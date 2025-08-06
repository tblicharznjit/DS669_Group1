USE mimiciii4;
CREATE TABLE urineOutput_1 AS
WITH urine_output AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    SUM(
      CASE
        WHEN oe.itemid = 227488 AND oe.value > 0 THEN -1 * oe.value
        ELSE oe.value
      END
    ) AS urineoutput
  FROM cohort sc
  JOIN icustays ie
    ON sc.subject_id = ie.subject_id
    AND sc.hadm_id = ie.hadm_id
    AND sc.icustay_id = ie.icustay_id
    AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
  LEFT JOIN outputevents oe
    ON ie.subject_id = oe.subject_id
    AND ie.hadm_id = oe.hadm_id
    AND ie.icustay_id = oe.icustay_id
    AND oe.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
  WHERE oe.itemid IN (
    -- CareVue urine output itemids
    40055, 43175, 40069, 40094, 40715, 40473, 40085, 40057, 40056, 40405, 40428, 40086, 40096, 40651,
    -- MetaVision urine output itemids
    226559, 226560, 226561, 226584, 226563, 226565, 226567, 226557, 226558, 227488, 227489
  )
  GROUP BY sc.subject_id, sc.hadm_id, sc.icustay_id, sc.earliestOnset
),
urine_output_final AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    COALESCE(uo.urineoutput, 0) AS urineoutput
  FROM cohort sc
  LEFT JOIN urine_output uo
    ON sc.subject_id = uo.subject_id
    AND sc.hadm_id = uo.hadm_id
    AND sc.icustay_id = uo.icustay_id
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  earliestOnset,
  urineoutput
FROM urine_output_final
ORDER BY subject_id, hadm_id, icustay_id;



-- Create urine output in 4-hour bins
DROP TABLE IF EXISTS urineOutput_4bin;
CREATE TABLE urineOutput_4bin AS
WITH urine_output_binned AS (
  SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    tb.earliestOnset,
    SUM(
      CASE
        WHEN oe.itemid = 227488 AND oe.value > 0 THEN -1 * oe.value
        ELSE oe.value
      END
    ) AS urineoutput_bin,
    COUNT(oe.value) AS urine_measurements,
    MIN(oe.charttime) AS first_measurement,
    MAX(oe.charttime) AS last_measurement
  FROM 4hr_time_bins tb
  LEFT JOIN outputevents oe
    ON tb.subject_id = oe.subject_id
    AND tb.hadm_id = oe.hadm_id
    AND tb.icustay_id = oe.icustay_id
    AND oe.charttime >= tb.bin_start_time
    AND oe.charttime < tb.bin_end_time
    AND oe.itemid IN (
      -- CareVue urine output itemids
      40055, 43175, 40069, 40094, 40715, 40473, 40085, 40057, 40056, 40405, 40428, 40086, 40096, 40651,
      -- MetaVision urine output itemids
      226559, 226560, 226561, 226584, 226563, 226565, 226567, 226557, 226558, 227488, 227489
    )
    AND oe.value IS NOT NULL
  GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
           tb.bin_start_time, tb.bin_end_time, tb.earliestOnset
),
urine_output_with_rates AS (
  SELECT 
    *,
    -- Calculate hourly urine output rate (ml/hour)
    CASE 
      WHEN urineoutput_bin IS NOT NULL THEN urineoutput_bin / 4.0
      ELSE NULL
    END AS urine_rate_ml_per_hour,
    -- Flag for oliguria (< 0.5 ml/kg/hr, using estimated 70kg adult)
    CASE 
      WHEN (urineoutput_bin / 4.0) < (0.5 * 70) THEN 1  -- < 35 ml/hr
      WHEN urineoutput_bin IS NULL THEN NULL
      ELSE 0
    END AS oliguria_flag,
    -- Flag for anuria (< 100 ml in 24 hours, so < 17 ml in 4 hours)
    CASE 
      WHEN urineoutput_bin < 17 THEN 1
      WHEN urineoutput_bin IS NULL THEN NULL
      ELSE 0
    END AS anuria_flag
  FROM urine_output_binned
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  COALESCE(urineoutput_bin, 0) AS urineoutput,
  COALESCE(urine_rate_ml_per_hour, 0) AS urine_rate_ml_per_hour,
  urine_measurements,
  first_measurement,
  last_measurement,
  COALESCE(oliguria_flag, 0) AS oliguria_flag,
  COALESCE(anuria_flag, 0) AS anuria_flag
FROM urine_output_with_rates
ORDER BY icustay_id, hour_offset;

-- Add indexes
CREATE INDEX idx_urine_4bin_icustay ON urineOutput_4bin(icustay_id);
CREATE INDEX idx_urine_4bin_hour ON urineOutput_4bin(hour_offset);
CREATE INDEX idx_urine_4bin_composite ON urineOutput_4bin(subject_id, hadm_id, icustay_id, hour_offset);
CREATE INDEX idx_urine_4bin_rate ON urineOutput_4bin(urine_rate_ml_per_hour);

-- Create imputed urine output table
DROP TABLE IF EXISTS urineOutput_4bin_imputed;
CREATE TABLE urineOutput_4bin_imputed AS
WITH urine_stats AS (
  -- Calculate patient-level statistics
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    AVG(CASE WHEN urineoutput > 0 THEN urineoutput END) AS patient_mean_urine,
    AVG(CASE WHEN urine_rate_ml_per_hour > 0 THEN urine_rate_ml_per_hour END) AS patient_mean_rate
  FROM urineOutput_4bin
  WHERE urineoutput > 0
  GROUP BY subject_id, hadm_id, icustay_id
),
population_stats AS (
  -- Calculate population-level statistics
  SELECT 
    AVG(CASE WHEN urineoutput > 0 THEN urineoutput END) AS pop_mean_urine,
    AVG(CASE WHEN urine_rate_ml_per_hour > 0 THEN urine_rate_ml_per_hour END) AS pop_mean_rate
  FROM urineOutput_4bin
  WHERE urineoutput > 0
),
forward_filled AS (
  -- Add forward and backward fill
  SELECT 
    uo.*,
    -- Forward fill (carry last observation forward)
    LAG(CASE WHEN urineoutput > 0 THEN urineoutput END, 1) 
      OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_urine,
    LAG(CASE WHEN urine_rate_ml_per_hour > 0 THEN urine_rate_ml_per_hour END, 1) 
      OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_rate,
    -- Backward fill (next observation carried backward)
    LEAD(CASE WHEN urineoutput > 0 THEN urineoutput END, 1) 
      OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_urine,
    LEAD(CASE WHEN urine_rate_ml_per_hour > 0 THEN urine_rate_ml_per_hour END, 1) 
      OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_rate
  FROM urineOutput_4bin uo
)
SELECT 
  ff.subject_id,
  ff.hadm_id,
  ff.icustay_id,
  ff.hour_offset,
  ff.bin_start_time,
  ff.bin_end_time,
  ff.earliestOnset,
  -- Original values
  ff.urineoutput AS urineoutput_original,
  ff.urine_rate_ml_per_hour AS urine_rate_original,
  -- Imputed urine output (ml per 4-hour bin)
  COALESCE(
    CASE WHEN ff.urineoutput > 0 THEN ff.urineoutput END,  -- Original value
    ff.prev_urine,                                         -- Forward fill
    ff.next_urine,                                         -- Backward fill
    us.patient_mean_urine,                                 -- Patient mean
    ps.pop_mean_urine,                                     -- Population mean
    140                                                    -- Clinical default (35 ml/hr * 4 hrs)
  ) AS urineoutput,
  -- Imputed urine rate (ml per hour)
  COALESCE(
    CASE WHEN ff.urine_rate_ml_per_hour > 0 THEN ff.urine_rate_ml_per_hour END,
    ff.prev_rate,
    ff.next_rate,
    us.patient_mean_rate,
    ps.pop_mean_rate,
    35                                                     -- Clinical default (35 ml/hr)
  ) AS urine_rate_ml_per_hour,
  -- Metadata
  ff.urine_measurements,
  ff.first_measurement,
  ff.last_measurement,
  -- Clinical flags (recalculated with imputed values)
  CASE 
    WHEN COALESCE(
      CASE WHEN ff.urine_rate_ml_per_hour > 0 THEN ff.urine_rate_ml_per_hour END,
      ff.prev_rate, ff.next_rate, us.patient_mean_rate, ps.pop_mean_rate, 35
    ) < 35 THEN 1  -- Oliguria: < 0.5 ml/kg/hr for 70kg adult
    ELSE 0
  END AS oliguria_flag,
  
  CASE 
    WHEN COALESCE(
      CASE WHEN ff.urineoutput > 0 THEN ff.urineoutput END,
      ff.prev_urine, ff.next_urine, us.patient_mean_urine, ps.pop_mean_urine, 140
    ) < 17 THEN 1  -- Anuria: < 100 ml/24hr (17 ml/4hr)
    ELSE 0
  END AS anuria_flag,
  -- Imputation flags
  CASE WHEN ff.urineoutput = 0 OR ff.urineoutput IS NULL THEN 1 ELSE 0 END AS urine_imputed

FROM forward_filled ff
LEFT JOIN urine_stats us
  ON ff.subject_id = us.subject_id
  AND ff.hadm_id = us.hadm_id
  AND ff.icustay_id = us.icustay_id
CROSS JOIN population_stats ps
ORDER BY ff.icustay_id, ff.hour_offset;

-- Add indexes for imputed table
CREATE INDEX idx_urine_imp_icustay ON urineOutput_4bin_imputed(icustay_id);
CREATE INDEX idx_urine_imp_hour ON urineOutput_4bin_imputed(hour_offset);
CREATE INDEX idx_urine_imp_oliguria ON urineOutput_4bin_imputed(oliguria_flag);
CREATE INDEX idx_urine_imp_anuria ON urineOutput_4bin_imputed(anuria_flag);

SELECT * from `urineOutput_4bin_imputed`;