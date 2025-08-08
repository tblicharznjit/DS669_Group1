CREATE TABLE bloodGasArterial_1 AS
WITH pvt AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    le.charttime,
    CASE
      WHEN le.itemid = 50800 THEN 'SPECIMEN'
      WHEN le.itemid = 50801 THEN 'AADO2'
      WHEN le.itemid = 50802 THEN 'BASEEXCESS'
      WHEN le.itemid = 50803 THEN 'BICARBONATE'
      WHEN le.itemid = 50804 THEN 'TOTALCO2'
      WHEN le.itemid = 50805 THEN 'CARBOXYHEMOGLOBIN'
      WHEN le.itemid = 50806 THEN 'CHLORIDE'
      WHEN le.itemid = 50808 THEN 'CALCIUM'
      WHEN le.itemid = 50809 THEN 'GLUCOSE'
      WHEN le.itemid = 50810 THEN 'HEMATOCRIT'
      WHEN le.itemid = 50811 THEN 'HEMOGLOBIN'
      WHEN le.itemid = 50812 THEN 'INTUBATED'
      WHEN le.itemid = 50813 THEN 'LACTATE'
      WHEN le.itemid = 50814 THEN 'METHEMOGLOBIN'
      WHEN le.itemid = 50815 THEN 'O2FLOW'
      WHEN le.itemid = 50816 THEN 'FIO2'
      WHEN le.itemid = 50817 THEN 'SO2'
      WHEN le.itemid = 50818 THEN 'PCO2'
      WHEN le.itemid = 50819 THEN 'PEEP'
      WHEN le.itemid = 50820 THEN 'PH'
      WHEN le.itemid = 50821 THEN 'PO2'
      WHEN le.itemid = 50822 THEN 'POTASSIUM'
      WHEN le.itemid = 50823 THEN 'REQUIREDO2'
      WHEN le.itemid = 50824 THEN 'SODIUM'
      WHEN le.itemid = 50825 THEN 'TEMPERATURE'
      WHEN le.itemid = 50826 THEN 'TIDALVOLUME'
      WHEN le.itemid = 50827 THEN 'VENTILATIONRATE'
      WHEN le.itemid = 50828 THEN 'VENTILATOR'
      ELSE NULL
    END AS label,
    le.value,
    CASE
      WHEN le.valuenum <= 0 AND le.itemid != 50802 THEN NULL -- Allow negative baseexcess
      WHEN le.itemid = 50810 AND le.valuenum > 100 THEN NULL -- Hematocrit
      WHEN le.itemid = 50816 AND le.valuenum < 20 THEN NULL -- FiO2
      WHEN le.itemid = 50816 AND le.valuenum > 100 THEN NULL -- FiO2
      WHEN le.itemid = 50817 AND le.valuenum > 100 THEN NULL -- SO2
      WHEN le.itemid = 50815 AND le.valuenum > 70 THEN NULL -- O2 flow
      WHEN le.itemid = 50821 AND le.valuenum > 800 THEN NULL -- PO2
      ELSE le.valuenum
    END AS valuenum
  FROM cohort sc
  JOIN icustays ie
    ON sc.subject_id = ie.subject_id
    AND sc.hadm_id = ie.hadm_id
    AND sc.icustay_id = ie.icustay_id
    AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
  LEFT JOIN labevents le
    ON sc.subject_id = le.subject_id
    AND sc.hadm_id = le.hadm_id
    AND le.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
    AND le.itemid IN (
      50800, 50801, 50802, 50803, 50804, 50805, 50806, 50808, 50809, 50810,
      50811, 50812, 50813, 50814, 50815, 50816, 50817, 50818, 50819, 50820,
      50821, 50822, 50823, 50824, 50825, 50826, 50827, 50828, 51545
    )
),
blood_gas_first_day AS (
  SELECT 
    pvt.subject_id,
    pvt.hadm_id,
    pvt.icustay_id,
    pvt.earliestOnset,
    pvt.charttime,
    MAX(CASE WHEN pvt.label = 'SPECIMEN' THEN pvt.value ELSE NULL END) AS specimen,
    MAX(CASE WHEN pvt.label = 'AADO2' THEN pvt.valuenum ELSE NULL END) AS aado2,
    MAX(CASE WHEN pvt.label = 'BASEEXCESS' THEN pvt.valuenum ELSE NULL END) AS baseexcess,
    MAX(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate,
    MAX(CASE WHEN pvt.label = 'TOTALCO2' THEN pvt.valuenum ELSE NULL END) AS totalco2,
    MAX(CASE WHEN pvt.label = 'CARBOXYHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS carboxyhemoglobin,
    MAX(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride,
    MAX(CASE WHEN pvt.label = 'CALCIUM' THEN pvt.valuenum ELSE NULL END) AS calcium,
    MAX(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose,
    MAX(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit,
    MAX(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin,
    MAX(CASE WHEN pvt.label = 'INTUBATED' THEN pvt.valuenum ELSE NULL END) AS intubated,
    MAX(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate,
    MAX(CASE WHEN pvt.label = 'METHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS methemoglobin,
    MAX(CASE WHEN pvt.label = 'O2FLOW' THEN pvt.valuenum ELSE NULL END) AS o2flow,
    MAX(CASE WHEN pvt.label = 'FIO2' THEN pvt.valuenum ELSE NULL END) AS fio2,
    MAX(CASE WHEN pvt.label = 'SO2' THEN pvt.valuenum ELSE NULL END) AS so2,
    MAX(CASE WHEN pvt.label = 'PCO2' THEN pvt.valuenum ELSE NULL END) AS pco2,
    MAX(CASE WHEN pvt.label = 'PEEP' THEN pvt.valuenum ELSE NULL END) AS peep,
    MAX(CASE WHEN pvt.label = 'PH' THEN pvt.valuenum ELSE NULL END) AS ph,
    MAX(CASE WHEN pvt.label = 'PO2' THEN pvt.valuenum ELSE NULL END) AS po2,
    MAX(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium,
    MAX(CASE WHEN pvt.label = 'REQUIREDO2' THEN pvt.valuenum ELSE NULL END) AS requiredo2,
    MAX(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium,
    MAX(CASE WHEN pvt.label = 'TEMPERATURE' THEN pvt.valuenum ELSE NULL END) AS temperature,
    MAX(CASE WHEN pvt.label = 'TIDALVOLUME' THEN pvt.valuenum ELSE NULL END) AS tidalvolume,
    MAX(CASE WHEN pvt.label = 'VENTILATIONRATE' THEN pvt.valuenum ELSE NULL END) AS ventilationrate,
    MAX(CASE WHEN pvt.label = 'VENTILATOR' THEN pvt.valuenum ELSE NULL END) AS ventilator
  FROM pvt
  WHERE pvt.label IS NOT NULL
  GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.earliestOnset, pvt.charttime
),
stg_spo2 AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    charttime,
    MAX(CASE WHEN valuenum <= 0 OR valuenum > 100 THEN NULL ELSE valuenum END) AS spo2
  FROM chartevents
  WHERE itemid IN (
    646, -- SpO2
    220277 -- O2 saturation pulseoxymetry
  )
  GROUP BY subject_id, hadm_id, icustay_id, charttime
),
stg_fio2 AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    charttime,
    MAX(
      CASE
        WHEN itemid = 223835 THEN
          CASE
            WHEN valuenum > 0 AND valuenum <= 1 THEN valuenum * 100
            WHEN valuenum > 1 AND valuenum < 21 THEN NULL
            WHEN valuenum >= 21 AND valuenum <= 100 THEN valuenum
            ELSE NULL
          END
        WHEN itemid IN (3420, 3422) THEN valuenum
        WHEN itemid = 190 AND valuenum > 0.20 AND valuenum < 1 THEN valuenum * 100
        ELSE NULL
      END
    ) AS fio2_chartevents
  FROM chartevents
  WHERE itemid IN (
    3420, -- FiO2
    190, -- FiO2 set
    223835, -- Inspired O2 Fraction (FiO2)
    3422 -- FiO2 [measured]
  )
  AND (error IS NULL OR error = 0)
  GROUP BY subject_id, hadm_id, icustay_id, charttime
),
stg2 AS (
  SELECT 
    bg.*,
    ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.charttime ORDER BY s1.charttime DESC) AS lastRowSpO2,
    s1.spo2
  FROM blood_gas_first_day bg
  LEFT JOIN stg_spo2 s1
    ON bg.icustay_id = s1.icustay_id
    AND s1.charttime BETWEEN DATE_SUB(bg.charttime, INTERVAL 2 HOUR) AND bg.charttime
  WHERE bg.po2 IS NOT NULL
),
stg3 AS (
  SELECT 
    bg.*,
    ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.charttime ORDER BY s2.charttime DESC) AS lastRowFiO2,
    s2.fio2_chartevents,
    1 / (1 + EXP(-(
      -0.02544
      + 0.04598 * bg.po2
      + COALESCE(-0.15356 * bg.spo2, -0.15356 * 97.49420 + 0.13429)
      + COALESCE(0.00621 * s2.fio2_chartevents, 0.00621 * 51.49550 + -0.24958)
      + COALESCE(0.10559 * bg.hemoglobin, 0.10559 * 10.32307 + 0.05954)
      + COALESCE(0.13251 * bg.so2, 0.13251 * 93.66539 + -0.23172)
      + COALESCE(-0.01511 * bg.pco2, -0.01511 * 42.08866 + -0.01630)
      + COALESCE(0.01480 * bg.fio2, 0.01480 * 63.97836 + -0.31142)
      + COALESCE(-0.00200 * bg.aado2, -0.00200 * 442.21186 + -0.01328)
      + COALESCE(-0.03220 * bg.bicarbonate, -0.03220 * 22.96894 + -0.06535)
      + COALESCE(0.05384 * bg.totalco2, 0.05384 * 24.72632 + -0.01405)
      + COALESCE(0.08202 * bg.lactate, 0.08202 * 3.06436 + 0.06038)
      + COALESCE(0.10956 * bg.ph, 0.10956 * 7.36233 + -0.00617)
      + COALESCE(0.00848 * bg.o2flow, 0.00848 * 7.59362 + -0.35803)
    ))) AS specimen_prob
  FROM stg2 bg
  LEFT JOIN stg_fio2 s2
    ON bg.icustay_id = s2.icustay_id
    AND s2.charttime BETWEEN DATE_SUB(bg.charttime, INTERVAL 4 HOUR) AND bg.charttime
  WHERE bg.lastRowSpO2 = 1
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  earliestOnset,
  charttime,
  specimen,
  CASE
    WHEN specimen IS NOT NULL THEN specimen
    WHEN specimen_prob > 0.75 THEN 'ART'
    ELSE NULL
  END AS specimen_pred,
  specimen_prob,
  so2,
  spo2,
  po2,
  pco2,
  fio2_chartevents,
  fio2,
  CASE
    WHEN po2 IS NOT NULL
    AND pco2 IS NOT NULL
    AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN (COALESCE(fio2, fio2_chartevents) / 100) * (760 - 47) - (pco2 / 0.8) - po2
    ELSE NULL
  END AS aado2_calc,
  CASE
    WHEN po2 IS NOT NULL AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN 100 * po2 / COALESCE(fio2, fio2_chartevents)
    ELSE NULL
  END AS pao2fio2,
  ph,
  baseexcess,
  bicarbonate,
  totalco2,
  hematocrit,
  hemoglobin,
  carboxyhemoglobin,
  methemoglobin,
  chloride,
  calcium,
  temperature,
  potassium,
  sodium,
  lactate,
  glucose,
  intubated,
  tidalvolume,
  ventilationrate,
  ventilator,
  peep,
  o2flow,
  requiredo2
FROM stg3
WHERE lastRowFiO2 = 1
AND (specimen = 'ART' OR specimen_prob > 0.75)
ORDER BY icustay_id, charttime;



-- Step 1: Create pivot table for lab events within time bins
DROP TABLE IF EXISTS temp_bg_pvt;
CREATE TABLE temp_bg_pvt AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  le.charttime,
  CASE
    WHEN le.itemid = 50800 THEN 'SPECIMEN'
    WHEN le.itemid = 50801 THEN 'AADO2'
    WHEN le.itemid = 50802 THEN 'BASEEXCESS'
    WHEN le.itemid = 50803 THEN 'BICARBONATE'
    WHEN le.itemid = 50804 THEN 'TOTALCO2'
    WHEN le.itemid = 50805 THEN 'CARBOXYHEMOGLOBIN'
    WHEN le.itemid = 50806 THEN 'CHLORIDE'
    WHEN le.itemid = 50808 THEN 'CALCIUM'
    WHEN le.itemid = 50809 THEN 'GLUCOSE'
    WHEN le.itemid = 50810 THEN 'HEMATOCRIT'
    WHEN le.itemid = 50811 THEN 'HEMOGLOBIN'
    WHEN le.itemid = 50812 THEN 'INTUBATED'
    WHEN le.itemid = 50813 THEN 'LACTATE'
    WHEN le.itemid = 50814 THEN 'METHEMOGLOBIN'
    WHEN le.itemid = 50815 THEN 'O2FLOW'
    WHEN le.itemid = 50816 THEN 'FIO2'
    WHEN le.itemid = 50817 THEN 'SO2'
    WHEN le.itemid = 50818 THEN 'PCO2'
    WHEN le.itemid = 50819 THEN 'PEEP'
    WHEN le.itemid = 50820 THEN 'PH'
    WHEN le.itemid = 50821 THEN 'PO2'
    WHEN le.itemid = 50822 THEN 'POTASSIUM'
    WHEN le.itemid = 50823 THEN 'REQUIREDO2'
    WHEN le.itemid = 50824 THEN 'SODIUM'
    WHEN le.itemid = 50825 THEN 'TEMPERATURE'
    WHEN le.itemid = 50826 THEN 'TIDALVOLUME'
    WHEN le.itemid = 50827 THEN 'VENTILATIONRATE'
    WHEN le.itemid = 50828 THEN 'VENTILATOR'
    WHEN le.itemid = 50960 THEN 'MAGNESIUM'
    WHEN le.itemid = 50861 THEN 'SGPT_ALT'
    WHEN le.itemid = 50878 THEN 'SGOT_AST'
    ELSE NULL
  END AS label,
  le.value,
  CASE
    WHEN le.valuenum <= 0 AND le.itemid != 50802 THEN NULL -- Allow negative baseexcess
    WHEN le.itemid = 50810 AND le.valuenum > 100 THEN NULL -- Hematocrit
    WHEN le.itemid = 50816 AND le.valuenum < 20 THEN NULL -- FiO2
    WHEN le.itemid = 50816 AND le.valuenum > 100 THEN NULL -- FiO2
    WHEN le.itemid = 50817 AND le.valuenum > 100 THEN NULL -- SO2
    WHEN le.itemid = 50815 AND le.valuenum > 70 THEN NULL -- O2 flow
    WHEN le.itemid = 50821 AND le.valuenum > 800 THEN NULL -- PO2
    WHEN le.itemid = 50960 AND (le.valuenum < 0.5 OR le.valuenum > 5.0) THEN NULL -- Magnesium
    WHEN le.itemid IN (50861, 50878) AND (le.valuenum <= 0 OR le.valuenum > 1000) THEN NULL -- Liver enzymes
    ELSE le.valuenum
  END AS valuenum
FROM 4hr_time_bins tb
LEFT JOIN labevents le
  ON tb.subject_id = le.subject_id
  AND tb.hadm_id = le.hadm_id
  AND le.charttime >= tb.bin_start_time
  AND le.charttime < tb.bin_end_time
  AND le.itemid IN (
    50800, 50801, 50802, 50803, 50804, 50805, 50806, 50808, 50809, 50810,
    50811, 50812, 50813, 50814, 50815, 50816, 50817, 50818, 50819, 50820,
    50821, 50822, 50823, 50824, 50825, 50826, 50827, 50828, 50960, 50861, 50878
  );

CREATE INDEX idx_temp_bg_pvt ON temp_bg_pvt(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 2: Aggregate blood gas measurements by bin and charttime
DROP TABLE IF EXISTS temp_bg_agg_by_time;
CREATE TABLE temp_bg_agg_by_time AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  charttime,
  MAX(CASE WHEN label = 'SPECIMEN' THEN value ELSE NULL END) AS specimen,
  MAX(CASE WHEN label = 'AADO2' THEN valuenum ELSE NULL END) AS aado2,
  MAX(CASE WHEN label = 'BASEEXCESS' THEN valuenum ELSE NULL END) AS baseexcess,
  MAX(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE NULL END) AS bicarbonate,
  MAX(CASE WHEN label = 'TOTALCO2' THEN valuenum ELSE NULL END) AS totalco2,
  MAX(CASE WHEN label = 'CARBOXYHEMOGLOBIN' THEN valuenum ELSE NULL END) AS carboxyhemoglobin,
  MAX(CASE WHEN label = 'CHLORIDE' THEN valuenum ELSE NULL END) AS chloride,
  MAX(CASE WHEN label = 'CALCIUM' THEN valuenum ELSE NULL END) AS calcium,
  MAX(CASE WHEN label = 'GLUCOSE' THEN valuenum ELSE NULL END) AS glucose,
  MAX(CASE WHEN label = 'HEMATOCRIT' THEN valuenum ELSE NULL END) AS hematocrit,
  MAX(CASE WHEN label = 'HEMOGLOBIN' THEN valuenum ELSE NULL END) AS hemoglobin,
  MAX(CASE WHEN label = 'INTUBATED' THEN valuenum ELSE NULL END) AS intubated,
  MAX(CASE WHEN label = 'LACTATE' THEN valuenum ELSE NULL END) AS lactate,
  MAX(CASE WHEN label = 'METHEMOGLOBIN' THEN valuenum ELSE NULL END) AS methemoglobin,
  MAX(CASE WHEN label = 'O2FLOW' THEN valuenum ELSE NULL END) AS o2flow,
  MAX(CASE WHEN label = 'FIO2' THEN valuenum ELSE NULL END) AS fio2,
  MAX(CASE WHEN label = 'SO2' THEN valuenum ELSE NULL END) AS so2,
  MAX(CASE WHEN label = 'PCO2' THEN valuenum ELSE NULL END) AS pco2,
  MAX(CASE WHEN label = 'PEEP' THEN valuenum ELSE NULL END) AS peep,
  MAX(CASE WHEN label = 'PH' THEN valuenum ELSE NULL END) AS ph,
  MAX(CASE WHEN label = 'PO2' THEN valuenum ELSE NULL END) AS po2,
  MAX(CASE WHEN label = 'POTASSIUM' THEN valuenum ELSE NULL END) AS potassium,
  MAX(CASE WHEN label = 'REQUIREDO2' THEN valuenum ELSE NULL END) AS requiredo2,
  MAX(CASE WHEN label = 'SODIUM' THEN valuenum ELSE NULL END) AS sodium,
  MAX(CASE WHEN label = 'TEMPERATURE' THEN valuenum ELSE NULL END) AS temperature,
  MAX(CASE WHEN label = 'TIDALVOLUME' THEN valuenum ELSE NULL END) AS tidalvolume,
  MAX(CASE WHEN label = 'VENTILATIONRATE' THEN valuenum ELSE NULL END) AS ventilationrate,
  MAX(CASE WHEN label = 'VENTILATOR' THEN valuenum ELSE NULL END) AS ventilator,
  MAX(CASE WHEN label = 'MAGNESIUM' THEN valuenum ELSE NULL END) AS magnesium,
  MAX(CASE WHEN label = 'SGPT_ALT' THEN valuenum ELSE NULL END) AS sgpt_alt,
  MAX(CASE WHEN label = 'SGOT_AST' THEN valuenum ELSE NULL END) AS sgot_ast
FROM temp_bg_pvt
WHERE label IS NOT NULL
GROUP BY subject_id, hadm_id, icustay_id, hour_offset, bin_start_time, bin_end_time, earliestOnset, charttime;

CREATE INDEX idx_temp_bg_agg_time ON temp_bg_agg_by_time(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 3: Get SpO2 from chartevents by time bin
DROP TABLE IF EXISTS temp_spo2_by_bin;
CREATE TABLE temp_spo2_by_bin AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  ce.charttime,
  MAX(CASE WHEN ce.valuenum <= 0 OR ce.valuenum > 100 THEN NULL ELSE ce.valuenum END) AS spo2
FROM 4hr_time_bins tb
LEFT JOIN chartevents ce
  ON tb.icustay_id = ce.icustay_id
  AND ce.charttime >= tb.bin_start_time
  AND ce.charttime < tb.bin_end_time
  AND ce.itemid IN (646, 220277) -- SpO2
  AND ce.valuenum IS NOT NULL
  AND (ce.error IS NULL OR ce.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, ce.charttime;

CREATE INDEX idx_temp_spo2_bin ON temp_spo2_by_bin(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 4: Get FiO2 from chartevents by time bin
DROP TABLE IF EXISTS temp_fio2_by_bin;
CREATE TABLE temp_fio2_by_bin AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  ce.charttime,
  MAX(
    CASE
      WHEN ce.itemid = 223835 THEN
        CASE
          WHEN ce.valuenum > 0 AND ce.valuenum <= 1 THEN ce.valuenum * 100
          WHEN ce.valuenum > 1 AND ce.valuenum < 21 THEN NULL
          WHEN ce.valuenum >= 21 AND ce.valuenum <= 100 THEN ce.valuenum
          ELSE NULL
        END
      WHEN ce.itemid IN (3420, 3422) THEN ce.valuenum
      WHEN ce.itemid = 190 AND ce.valuenum > 0.20 AND ce.valuenum < 1 THEN ce.valuenum * 100
      ELSE NULL
    END
  ) AS fio2_chartevents
FROM 4hr_time_bins tb
LEFT JOIN chartevents ce
  ON tb.icustay_id = ce.icustay_id
  AND ce.charttime >= tb.bin_start_time
  AND ce.charttime < tb.bin_end_time
  AND ce.itemid IN (3420, 190, 223835, 3422)
  AND ce.valuenum IS NOT NULL
  AND (ce.error IS NULL OR ce.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, ce.charttime;

CREATE INDEX idx_temp_fio2_bin ON temp_fio2_by_bin(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 5: Join blood gas with SpO2 (matching nearest time within 2 hours)
DROP TABLE IF EXISTS temp_bg_with_spo2;
CREATE TABLE temp_bg_with_spo2 AS
SELECT 
  bg.*,
  spo2.spo2,
  ROW_NUMBER() OVER (
    PARTITION BY bg.subject_id, bg.hadm_id, bg.icustay_id, bg.hour_offset, bg.charttime 
    ORDER BY ABS(TIMESTAMPDIFF(MINUTE, bg.charttime, spo2.charttime))
  ) AS spo2_rank
FROM temp_bg_agg_by_time bg
LEFT JOIN temp_spo2_by_bin spo2
  ON bg.subject_id = spo2.subject_id
  AND bg.hadm_id = spo2.hadm_id
  AND bg.icustay_id = spo2.icustay_id
  AND bg.hour_offset = spo2.hour_offset
  AND ABS(TIMESTAMPDIFF(MINUTE, bg.charttime, spo2.charttime)) <= 120 -- Within 2 hours
WHERE bg.po2 IS NOT NULL; -- Only records with PO2

CREATE INDEX idx_temp_bg_spo2 ON temp_bg_with_spo2(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 6: Join with FiO2 and calculate specimen probability
DROP TABLE IF EXISTS temp_bg_with_fio2;
CREATE TABLE temp_bg_with_fio2 AS
SELECT 
  bg.*,
  fio2.fio2_chartevents,
  ROW_NUMBER() OVER (
    PARTITION BY bg.subject_id, bg.hadm_id, bg.icustay_id, bg.hour_offset, bg.charttime 
    ORDER BY ABS(TIMESTAMPDIFF(MINUTE, bg.charttime, fio2.charttime))
  ) AS fio2_rank,
  -- Calculate specimen probability using logistic regression
  1 / (1 + EXP(-(
    -0.02544
    + 0.04598 * bg.po2
    + COALESCE(-0.15356 * bg.spo2, -0.15356 * 97.49420 + 0.13429)
    + COALESCE(0.00621 * fio2.fio2_chartevents, 0.00621 * 51.49550 + -0.24958)
    + COALESCE(0.10559 * bg.hemoglobin, 0.10559 * 10.32307 + 0.05954)
    + COALESCE(0.13251 * bg.so2, 0.13251 * 93.66539 + -0.23172)
    + COALESCE(-0.01511 * bg.pco2, -0.01511 * 42.08866 + -0.01630)
    + COALESCE(0.01480 * bg.fio2, 0.01480 * 63.97836 + -0.31142)
    + COALESCE(-0.00200 * bg.aado2, -0.00200 * 442.21186 + -0.01328)
    + COALESCE(-0.03220 * bg.bicarbonate, -0.03220 * 22.96894 + -0.06535)
    + COALESCE(0.05384 * bg.totalco2, 0.05384 * 24.72632 + -0.01405)
    + COALESCE(0.08202 * bg.lactate, 0.08202 * 3.06436 + 0.06038)
    + COALESCE(0.10956 * bg.ph, 0.10956 * 7.36233 + -0.00617)
    + COALESCE(0.00848 * bg.o2flow, 0.00848 * 7.59362 + -0.35803)
  ))) AS specimen_prob
FROM temp_bg_with_spo2 bg
LEFT JOIN temp_fio2_by_bin fio2
  ON bg.subject_id = fio2.subject_id
  AND bg.hadm_id = fio2.hadm_id
  AND bg.icustay_id = fio2.icustay_id
  AND bg.hour_offset = fio2.hour_offset
  AND ABS(TIMESTAMPDIFF(MINUTE, bg.charttime, fio2.charttime)) <= 240 -- Within 4 hours
WHERE bg.spo2_rank = 1; -- Take closest SpO2 match

CREATE INDEX idx_temp_bg_fio2 ON temp_bg_with_fio2(subject_id, hadm_id, icustay_id, hour_offset, charttime);

-- Step 7: Create final blood gas arterial table with all bins
DROP TABLE IF EXISTS bloodGasArterial_4bin_detailed;
CREATE TABLE bloodGasArterial_4bin_detailed AS
SELECT 
  bg.subject_id,
  bg.hadm_id,
  bg.icustay_id,
  bg.hour_offset,
  bg.bin_start_time,
  bg.bin_end_time,
  bg.earliestOnset,
  bg.charttime,
  -- Specimen information
  bg.specimen,
  CASE
    WHEN bg.specimen IS NOT NULL THEN bg.specimen
    WHEN bg.specimen_prob > 0.75 THEN 'ART'
    ELSE NULL
  END AS specimen_pred,
  bg.specimen_prob,
  -- Respiratory parameters
  bg.so2,
  bg.spo2,
  bg.po2,
  bg.pco2,
  bg.fio2_chartevents,
  bg.fio2,
  -- Calculated values
  CASE
    WHEN bg.po2 IS NOT NULL
    AND bg.pco2 IS NOT NULL
    AND COALESCE(bg.fio2, bg.fio2_chartevents) IS NOT NULL
    THEN (COALESCE(bg.fio2, bg.fio2_chartevents) / 100) * (760 - 47) - (bg.pco2 / 0.8) - bg.po2
    ELSE NULL
  END AS aado2_calc,
  
  CASE
    WHEN bg.po2 IS NOT NULL AND COALESCE(bg.fio2, bg.fio2_chartevents) IS NOT NULL
    THEN 100 * bg.po2 / COALESCE(bg.fio2, bg.fio2_chartevents)
    ELSE NULL
  END AS pao2fio2,
  -- Blood gas parameters
  bg.ph,
  bg.baseexcess,
  bg.bicarbonate,
  bg.totalco2,
  bg.aado2,
  -- Blood parameters
  bg.hematocrit,
  bg.hemoglobin,
  bg.carboxyhemoglobin,
  bg.methemoglobin,
  -- Electrolytes
  bg.chloride,
  bg.calcium,
  bg.potassium,
  bg.sodium,
  -- Metabolic parameters
  bg.lactate,
  bg.glucose,
  bg.magnesium,
  bg.sgpt_alt,
  bg.sgot_ast,
  -- Temperature
  bg.temperature,
  -- Ventilation parameters
  bg.intubated,
  bg.tidalvolume,
  bg.ventilationrate,
  bg.ventilator,
  bg.peep,
  bg.o2flow,
  bg.requiredo2,
  -- Quality indicators
  bg.fio2_rank,
  CASE WHEN bg.fio2_rank = 1 THEN 1 ELSE 0 END AS best_fio2_match

FROM temp_bg_with_fio2 bg
WHERE bg.fio2_rank = 1 -- Take best FiO2 match
AND (bg.specimen = 'ART' OR bg.specimen_prob > 0.75 OR bg.specimen IS NULL) -- Include all potential arterial samples
ORDER BY bg.icustay_id, bg.hour_offset, bg.charttime;

select * from `bloodGasArterial_4bin_detailed`;

-- Create indexes for performance
CREATE INDEX idx_bg_detailed_icustay ON bloodGasArterial_4bin_detailed(icustay_id, hour_offset);
CREATE INDEX idx_bg_detailed_charttime ON bloodGasArterial_4bin_detailed(charttime);
CREATE INDEX idx_bg_detailed_composite ON bloodGasArterial_4bin_detailed(subject_id, hadm_id, icustay_id, hour_offset);

-- Step 8: Create aggregated version by time bin
DROP TABLE IF EXISTS bloodGasArterial_4bin_agg_enhanced;
CREATE TABLE bloodGasArterial_4bin_agg_enhanced AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  -- Count of measurements in bin
  COUNT(*) as measurement_count,
  -- First and last charttime in bin
  MIN(charttime) as first_charttime,
  MAX(charttime) as last_charttime,
  -- Specimen information (most common)
  MAX(specimen) as specimen,
  MAX(specimen_pred) as specimen_pred,
  AVG(specimen_prob) as avg_specimen_prob,
  -- Respiratory parameters (averages)
  AVG(so2) as so2_avg,
  MIN(so2) as so2_min,
  MAX(so2) as so2_max,
  AVG(spo2) as spo2_avg,
  MIN(spo2) as spo2_min,
  MAX(spo2) as spo2_max,
  AVG(po2) as po2_avg,
  MIN(po2) as po2_min,
  MAX(po2) as po2_max,
  AVG(pco2) as pco2_avg,
  MIN(pco2) as pco2_min,
  MAX(pco2) as pco2_max,
  AVG(fio2_chartevents) as fio2_chartevents_avg,
  AVG(fio2) as fio2_avg,
  MAX(fio2) as fio2_max,
  -- Calculated values
  AVG(aado2_calc) as aado2_calc_avg,
  AVG(pao2fio2) as pao2fio2_avg,
  MIN(pao2fio2) as pao2fio2_min,
  -- Blood gas parameters
  AVG(ph) as ph_avg,
  MIN(ph) as ph_min,
  MAX(ph) as ph_max,
  AVG(baseexcess) as baseexcess_avg,
  MIN(baseexcess) as baseexcess_min,
  MAX(baseexcess) as baseexcess_max,
  AVG(bicarbonate) as bicarbonate_avg,
  AVG(totalco2) as totalco2_avg,
  AVG(aado2) as aado2_avg,
  -- Blood parameters
  AVG(hematocrit) as hematocrit_avg,
  AVG(hemoglobin) as hemoglobin_avg,
  AVG(carboxyhemoglobin) as carboxyhemoglobin_avg,
  AVG(methemoglobin) as methemoglobin_avg,
  -- Electrolytes
  AVG(chloride) as chloride_avg,
  AVG(calcium) as calcium_avg,
  AVG(potassium) as potassium_avg,
  AVG(sodium) as sodium_avg,
  -- Metabolic parameters
  AVG(lactate) as lactate_avg,
  MAX(lactate) as lactate_max,
  AVG(glucose) as glucose_avg,
  MIN(glucose) as glucose_min,
  MAX(glucose) as glucose_max,
  AVG(magnesium) as magnesium_avg,
  MIN(magnesium) as magnesium_min,
  MAX(magnesium) as magnesium_max,
  AVG(sgpt_alt) as sgpt_alt_avg,
  MIN(sgpt_alt) as sgpt_alt_min,
  MAX(sgpt_alt) as sgpt_alt_max,
  AVG(sgot_ast) as sgot_ast_avg,
  MIN(sgot_ast) as sgot_ast_min,
  MAX(sgot_ast) as sgot_ast_max,
  -- Temperature
  AVG(temperature) as temperature_avg,
  -- Ventilation parameters
  MAX(intubated) as intubated,
  AVG(tidalvolume) as tidalvolume_avg,
  AVG(ventilationrate) as ventilationrate_avg,
  MAX(ventilator) as ventilator,
  AVG(peep) as peep_avg,
  AVG(o2flow) as o2flow_avg,
  MAX(requiredo2) as requiredo2

FROM bloodGasArterial_4bin_detailed
GROUP BY subject_id, hadm_id, icustay_id, hour_offset, bin_start_time, bin_end_time, earliestOnset
ORDER BY icustay_id, hour_offset;

-- Create indexes
CREATE INDEX idx_bg_agg_enh_icustay ON bloodGasArterial_4bin_agg_enhanced(icustay_id, hour_offset);
CREATE INDEX idx_bg_agg_enh_composite ON bloodGasArterial_4bin_agg_enhanced(subject_id, hadm_id, icustay_id, hour_offset);

-- Clean up temporary tables
DROP TABLE IF EXISTS temp_bg_pvt;
DROP TABLE IF EXISTS temp_bg_agg_by_time;
DROP TABLE IF EXISTS temp_spo2_by_bin;
DROP TABLE IF EXISTS temp_fio2_by_bin;
DROP TABLE IF EXISTS temp_bg_with_spo2;
DROP TABLE IF EXISTS temp_bg_with_fio2;

-- Verification queries
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT icustay_id) as unique_icustays,
    COUNT(DISTINCT CONCAT(icustay_id, '-', hour_offset)) as unique_bins,
    AVG(ph_avg) as avg_ph,
    AVG(glucose_avg) as avg_glucose,
    AVG(magnesium_avg) as avg_magnesium,
    AVG(sgpt_alt_avg) as avg_sgpt,
    AVG(sgot_ast_avg) as avg_sgot
FROM bloodGasArterial_4bin_agg_enhanced;

-- Check bin coverage per patient
SELECT 
    icustay_id,
    COUNT(hour_offset) as bin_count,
    MIN(hour_offset) as min_offset,
    MAX(hour_offset) as max_offset
FROM bloodGasArterial_4bin_agg_enhanced
GROUP BY icustay_id
ORDER BY bin_count;



-- Step 1: Extract only the required lab values using 4hr_time_bins
DROP TABLE IF EXISTS temp_bg_core_values;
CREATE TABLE temp_bg_core_values AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  -- Core blood gas values
  AVG(CASE WHEN le.itemid = 50820 THEN le.valuenum END) AS ph_avg,
  AVG(CASE WHEN le.itemid = 50821 THEN le.valuenum END) AS po2_avg,
  AVG(CASE WHEN le.itemid = 50818 THEN le.valuenum END) AS pco2_avg,
  AVG(CASE WHEN le.itemid = 50802 THEN le.valuenum END) AS baseexcess_avg,
  AVG(CASE WHEN le.itemid = 50803 THEN le.valuenum END) AS bicarbonate_avg,
  AVG(CASE WHEN le.itemid = 50816 THEN le.valuenum END) AS fio2_avg,
  AVG(CASE WHEN le.itemid = 50811 THEN le.valuenum END) AS hemoglobin_avg,
  AVG(CASE WHEN le.itemid = 50806 THEN le.valuenum END) AS chloride_avg,
  AVG(CASE WHEN le.itemid = 50808 THEN le.valuenum END) AS calcium_avg,
  AVG(CASE WHEN le.itemid = 50960 THEN le.valuenum END) AS magnesium_avg,
  AVG(CASE WHEN le.itemid = 50861 THEN le.valuenum END) AS sgpt_avg,
  AVG(CASE WHEN le.itemid = 50878 THEN le.valuenum END) AS sgot_avg
FROM 4hr_time_bins tb
LEFT JOIN labevents le
  ON tb.subject_id = le.subject_id
  AND tb.hadm_id = le.hadm_id
  AND le.charttime >= tb.bin_start_time
  AND le.charttime < tb.bin_end_time
  AND le.itemid IN (50820, 50821, 50818, 50802, 50803, 50816, 50811, 50806, 50808, 50960, 50861, 50878)
  AND le.valuenum IS NOT NULL
  AND CASE
    WHEN le.itemid = 50821 AND le.valuenum > 800 THEN FALSE -- PO2
    WHEN le.itemid = 50816 AND (le.valuenum < 20 OR le.valuenum > 100) THEN FALSE -- FiO2
    WHEN le.itemid = 50960 AND (le.valuenum < 0.5 OR le.valuenum > 5.0) THEN FALSE -- Magnesium
    WHEN le.itemid IN (50861, 50878) AND (le.valuenum <= 0 OR le.valuenum > 1000) THEN FALSE -- Liver enzymes
    WHEN le.valuenum <= 0 AND le.itemid != 50802 THEN FALSE -- Allow negative base excess
    ELSE TRUE
  END
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
         tb.bin_start_time, tb.bin_end_time, tb.earliestOnset;

CREATE INDEX idx_temp_bg_core ON temp_bg_core_values(icustay_id, hour_offset);

-- Step 2: Get FiO2 from chartevents
DROP TABLE IF EXISTS temp_fio2_chartevents;
CREATE TABLE temp_fio2_chartevents AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  AVG(
    CASE
      WHEN ce.itemid = 223835 THEN
        CASE
          WHEN ce.valuenum > 0 AND ce.valuenum <= 1 THEN ce.valuenum * 100
          WHEN ce.valuenum > 1 AND ce.valuenum < 21 THEN NULL
          WHEN ce.valuenum >= 21 AND ce.valuenum <= 100 THEN ce.valuenum
          ELSE NULL
        END
      WHEN ce.itemid IN (3420, 3422) THEN ce.valuenum
      WHEN ce.itemid = 190 AND ce.valuenum > 0.20 AND ce.valuenum < 1 THEN ce.valuenum * 100
      ELSE NULL
    END
  ) AS fio2_chartevents
FROM 4hr_time_bins tb
LEFT JOIN ceFiltered ce
  ON tb.icustay_id = ce.icustay_id
  AND ce.charttime >= tb.bin_start_time
  AND ce.charttime < tb.bin_end_time
  AND ce.itemid IN (3420, 190, 223835, 3422)
  AND ce.valuenum IS NOT NULL
  AND (ce.error IS NULL OR ce.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset;

CREATE INDEX idx_temp_fio2 ON temp_fio2_chartevents(icustay_id, hour_offset);

-- Step 3: Combine lab and chart values with calculated P/F ratio
DROP TABLE IF EXISTS temp_bg_combined;
CREATE TABLE temp_bg_combined AS
SELECT 
  bg.subject_id,
  bg.hadm_id,
  bg.icustay_id,
  bg.hour_offset,
  bg.bin_start_time,
  bg.bin_end_time,
  bg.earliestOnset,
  bg.ph_avg,
  bg.po2_avg,
  bg.pco2_avg,
  bg.baseexcess_avg,
  bg.bicarbonate_avg,
  bg.fio2_avg,
  fio2.fio2_chartevents,
  bg.hemoglobin_avg,
  bg.chloride_avg,
  bg.calcium_avg,
  bg.magnesium_avg,
  bg.sgpt_avg,
  bg.sgot_avg,
  -- Calculate P/F ratio
  CASE
    WHEN bg.po2_avg IS NOT NULL AND COALESCE(bg.fio2_avg, fio2.fio2_chartevents) IS NOT NULL
    THEN 100 * bg.po2_avg / COALESCE(bg.fio2_avg, fio2.fio2_chartevents)
    ELSE NULL
  END AS pao2fio2_avg
FROM temp_bg_core_values bg
LEFT JOIN temp_fio2_chartevents fio2
  ON bg.subject_id = fio2.subject_id
  AND bg.hadm_id = fio2.hadm_id
  AND bg.icustay_id = fio2.icustay_id
  AND bg.hour_offset = fio2.hour_offset;

CREATE INDEX idx_temp_bg_combined ON temp_bg_combined(icustay_id, hour_offset);

-- Step 4: Calculate patient-level statistics for imputation
DROP TABLE IF EXISTS temp_patient_stats;
CREATE TABLE temp_patient_stats AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  AVG(ph_avg) AS patient_ph_mean,
  AVG(po2_avg) AS patient_po2_mean,
  AVG(pco2_avg) AS patient_pco2_mean,
  AVG(pao2fio2_avg) AS patient_pao2fio2_mean,
  AVG(baseexcess_avg) AS patient_baseexcess_mean,
  AVG(bicarbonate_avg) AS patient_bicarbonate_mean,
  AVG(COALESCE(fio2_avg, fio2_chartevents)) AS patient_fio2_mean,
  AVG(hemoglobin_avg) AS patient_hemoglobin_mean,
  AVG(chloride_avg) AS patient_chloride_mean,
  AVG(calcium_avg) AS patient_calcium_mean,
  AVG(magnesium_avg) AS patient_magnesium_mean,
  AVG(sgpt_avg) AS patient_sgpt_mean,
  AVG(sgot_avg) AS patient_sgot_mean
FROM temp_bg_combined
WHERE ph_avg IS NOT NULL OR po2_avg IS NOT NULL OR pco2_avg IS NOT NULL
GROUP BY subject_id, hadm_id, icustay_id;

CREATE INDEX idx_temp_patient_stats ON temp_patient_stats(subject_id, hadm_id, icustay_id);

-- Step 5: Calculate population-level statistics for imputation
DROP TABLE IF EXISTS temp_population_stats;
CREATE TABLE temp_population_stats AS
SELECT 
  AVG(ph_avg) AS pop_ph_mean,
  AVG(po2_avg) AS pop_po2_mean,
  AVG(pco2_avg) AS pop_pco2_mean,
  AVG(pao2fio2_avg) AS pop_pao2fio2_mean,
  AVG(baseexcess_avg) AS pop_baseexcess_mean,
  AVG(bicarbonate_avg) AS pop_bicarbonate_mean,
  AVG(COALESCE(fio2_avg, fio2_chartevents)) AS pop_fio2_mean,
  AVG(hemoglobin_avg) AS pop_hemoglobin_mean,
  AVG(chloride_avg) AS pop_chloride_mean,
  AVG(calcium_avg) AS pop_calcium_mean,
  AVG(magnesium_avg) AS pop_magnesium_mean,
  AVG(sgpt_avg) AS pop_sgpt_mean,
  AVG(sgot_avg) AS pop_sgot_mean
FROM temp_bg_combined
WHERE ph_avg IS NOT NULL OR po2_avg IS NOT NULL OR pco2_avg IS NOT NULL;

-- Step 6: Create forward/backward fill values
DROP TABLE IF EXISTS temp_filled_values;
CREATE TABLE temp_filled_values AS
SELECT 
  bg.*,
  ps.patient_ph_mean, ps.patient_po2_mean, ps.patient_pco2_mean, ps.patient_pao2fio2_mean,
  ps.patient_baseexcess_mean, ps.patient_bicarbonate_mean, ps.patient_fio2_mean,
  ps.patient_hemoglobin_mean, ps.patient_chloride_mean, ps.patient_calcium_mean,
  ps.patient_magnesium_mean, ps.patient_sgpt_mean, ps.patient_sgot_mean,
  -- Forward fill (LAG)
  LAG(bg.ph_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_ph,
  LAG(bg.po2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_po2,
  LAG(bg.pco2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_pco2,
  LAG(bg.pao2fio2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_pao2fio2,
  LAG(bg.baseexcess_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_baseexcess,
  LAG(bg.bicarbonate_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_bicarbonate,
  LAG(COALESCE(bg.fio2_avg, bg.fio2_chartevents), 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_fio2,
  LAG(bg.hemoglobin_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_hemoglobin,
  LAG(bg.chloride_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_chloride,
  LAG(bg.calcium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_calcium,
  LAG(bg.magnesium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_magnesium,
  LAG(bg.sgpt_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_sgpt,
  LAG(bg.sgot_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_sgot,
  -- Backward fill (LEAD)
  LEAD(bg.ph_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_ph,
  LEAD(bg.po2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_po2,
  LEAD(bg.pco2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_pco2,
  LEAD(bg.pao2fio2_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_pao2fio2,
  LEAD(bg.baseexcess_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_baseexcess,
  LEAD(bg.bicarbonate_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_bicarbonate,
  LEAD(COALESCE(bg.fio2_avg, bg.fio2_chartevents), 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_fio2,
  LEAD(bg.hemoglobin_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_hemoglobin,
  LEAD(bg.chloride_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_chloride,
  LEAD(bg.calcium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_calcium,
  LEAD(bg.magnesium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_magnesium,
  LEAD(bg.sgpt_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_sgpt,
  LEAD(bg.sgot_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_sgot
  
FROM temp_bg_combined bg
LEFT JOIN temp_patient_stats ps
  ON bg.subject_id = ps.subject_id
  AND bg.hadm_id = ps.hadm_id
  AND bg.icustay_id = ps.icustay_id;

CREATE INDEX idx_temp_filled ON temp_filled_values(icustay_id, hour_offset);

-- Step 7: Final table with hierarchical imputation
DROP TABLE IF EXISTS bloodGasArterial_4bin_imputed;
CREATE TABLE bloodGasArterial_4bin_imputed AS
SELECT 
  fv.subject_id,
  fv.hadm_id,
  fv.icustay_id,
  fv.hour_offset,
  fv.bin_start_time,
  fv.bin_end_time,
  fv.earliestOnset,
  -- Original values
  fv.ph_avg,
  fv.po2_avg,
  fv.pco2_avg,
  fv.pao2fio2_avg,
  fv.baseexcess_avg,
  fv.bicarbonate_avg,
  fv.fio2_avg,
  fv.fio2_chartevents,
  fv.hemoglobin_avg,
  fv.chloride_avg,
  fv.calcium_avg,
  fv.magnesium_avg,
  fv.sgpt_avg,
  fv.sgot_avg,
  -- Population means for reference
  ps.pop_ph_mean,
  ps.pop_po2_mean,
  ps.pop_pco2_mean,
  ps.pop_pao2fio2_mean,
  ps.pop_baseexcess_mean,
  ps.pop_bicarbonate_mean,
  ps.pop_fio2_mean,
  ps.pop_hemoglobin_mean,
  ps.pop_chloride_mean,
  ps.pop_calcium_mean,
  ps.pop_magnesium_mean,
  ps.pop_sgpt_mean,
  ps.pop_sgot_mean,
  -- HIERARCHICAL IMPUTATION: measured → forward fill → backward fill → patient mean → population mean → normal values
  COALESCE(fv.ph_avg, fv.prev_ph, fv.next_ph, fv.patient_ph_mean, ps.pop_ph_mean, 7.40) AS ph_imputed,
  COALESCE(fv.po2_avg, fv.prev_po2, fv.next_po2, fv.patient_po2_mean, ps.pop_po2_mean, 95) AS po2_imputed,
  COALESCE(fv.pco2_avg, fv.prev_pco2, fv.next_pco2, fv.patient_pco2_mean, ps.pop_pco2_mean, 40) AS pco2_imputed,
  COALESCE(fv.pao2fio2_avg, fv.prev_pao2fio2, fv.next_pao2fio2, fv.patient_pao2fio2_mean, ps.pop_pao2fio2_mean, 400) AS pao2fio2_imputed,
  COALESCE(fv.baseexcess_avg, fv.prev_baseexcess, fv.next_baseexcess, fv.patient_baseexcess_mean, ps.pop_baseexcess_mean, 0) AS baseexcess_imputed,
  COALESCE(fv.bicarbonate_avg, fv.prev_bicarbonate, fv.next_bicarbonate, fv.patient_bicarbonate_mean, ps.pop_bicarbonate_mean, 24) AS bicarbonate_imputed,
  COALESCE(COALESCE(fv.fio2_avg, fv.fio2_chartevents), fv.prev_fio2, fv.next_fio2, fv.patient_fio2_mean, ps.pop_fio2_mean, 21) AS fio2_imputed,
  COALESCE(fv.hemoglobin_avg, fv.prev_hemoglobin, fv.next_hemoglobin, fv.patient_hemoglobin_mean, ps.pop_hemoglobin_mean, 12) AS hemoglobin_imputed,
  COALESCE(fv.chloride_avg, fv.prev_chloride, fv.next_chloride, fv.patient_chloride_mean, ps.pop_chloride_mean, 102) AS chloride_imputed,
  COALESCE(fv.calcium_avg, fv.prev_calcium, fv.next_calcium, fv.patient_calcium_mean, ps.pop_calcium_mean, 9.5) AS calcium_imputed,
  COALESCE(fv.magnesium_avg, fv.prev_magnesium, fv.next_magnesium, fv.patient_magnesium_mean, ps.pop_magnesium_mean, 1.9) AS magnesium_imputed,
  COALESCE(fv.sgpt_avg, fv.prev_sgpt, fv.next_sgpt, fv.patient_sgpt_mean, ps.pop_sgpt_mean, 31) AS sgpt_imputed,
  COALESCE(fv.sgot_avg, fv.prev_sgot, fv.next_sgot, fv.patient_sgot_mean, ps.pop_sgot_mean, 38) AS sgot_imputed,
  -- Imputation flags (1 = imputed, 0 = measured)
  CASE WHEN fv.ph_avg IS NULL THEN 1 ELSE 0 END AS ph_imputed_flag,
  CASE WHEN fv.po2_avg IS NULL THEN 1 ELSE 0 END AS po2_imputed_flag,
  CASE WHEN fv.pco2_avg IS NULL THEN 1 ELSE 0 END AS pco2_imputed_flag,
  CASE WHEN fv.pao2fio2_avg IS NULL THEN 1 ELSE 0 END AS pao2fio2_imputed_flag,
  CASE WHEN fv.baseexcess_avg IS NULL THEN 1 ELSE 0 END AS baseexcess_imputed_flag,
  CASE WHEN fv.bicarbonate_avg IS NULL THEN 1 ELSE 0 END AS bicarbonate_imputed_flag,
  CASE WHEN COALESCE(fv.fio2_avg, fv.fio2_chartevents) IS NULL THEN 1 ELSE 0 END AS fio2_imputed_flag,
  CASE WHEN fv.hemoglobin_avg IS NULL THEN 1 ELSE 0 END AS hemoglobin_imputed_flag,
  CASE WHEN fv.chloride_avg IS NULL THEN 1 ELSE 0 END AS chloride_imputed_flag,
  CASE WHEN fv.calcium_avg IS NULL THEN 1 ELSE 0 END AS calcium_imputed_flag,
  CASE WHEN fv.magnesium_avg IS NULL THEN 1 ELSE 0 END AS magnesium_imputed_flag,
  CASE WHEN fv.sgpt_avg IS NULL THEN 1 ELSE 0 END AS sgpt_imputed_flag,
  CASE WHEN fv.sgot_avg IS NULL THEN 1 ELSE 0 END AS sgot_imputed_flag

FROM temp_filled_values fv
CROSS JOIN temp_population_stats ps
ORDER BY fv.icustay_id, fv.hour_offset;

-- Create indexes for performance
CREATE INDEX idx_bg_imputed_icustay ON bloodGasArterial_4bin_imputed(icustay_id, hour_offset);
CREATE INDEX idx_bg_imputed_composite ON bloodGasArterial_4bin_imputed(subject_id, hadm_id, icustay_id, hour_offset);

-- Clean up temporary tables
DROP TABLE IF EXISTS temp_bg_core_values;
DROP TABLE IF EXISTS temp_fio2_chartevents;
DROP TABLE IF EXISTS temp_bg_combined;
DROP TABLE IF EXISTS temp_patient_stats;
DROP TABLE IF EXISTS temp_population_stats;
DROP TABLE IF EXISTS temp_filled_values;

-- Verification
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT icustay_id) as unique_icustays,
    COUNT(DISTINCT CONCAT(icustay_id, '-', hour_offset)) as unique_bins,
    -- Average imputed values
    AVG(ph_imputed) as avg_ph,
    AVG(po2_imputed) as avg_po2,
    AVG(pco2_imputed) as avg_pco2,
    AVG(pao2fio2_imputed) as avg_pao2fio2,
    AVG(baseexcess_imputed) as avg_baseexcess,
    AVG(bicarbonate_imputed) as avg_bicarbonate,
    AVG(fio2_imputed) as avg_fio2,
    AVG(hemoglobin_imputed) as avg_hemoglobin,
    AVG(chloride_imputed) as avg_chloride,
    AVG(calcium_imputed) as avg_calcium,
    AVG(magnesium_imputed) as avg_magnesium,
    AVG(sgpt_imputed) as avg_sgpt,
    AVG(sgot_imputed) as avg_sgot,
    -- Imputation rates
    AVG(ph_imputed_flag) * 100 as ph_imputation_rate_pct,
    AVG(po2_imputed_flag) * 100 as po2_imputation_rate_pct,
    AVG(pco2_imputed_flag) * 100 as pco2_imputation_rate_pct,
    AVG(magnesium_imputed_flag) * 100 as magnesium_imputation_rate_pct,
    AVG(sgpt_imputed_flag) * 100 as sgpt_imputation_rate_pct,
    AVG(sgot_imputed_flag) * 100 as sgot_imputation_rate_pct
FROM bloodGasArterial_4bin_imputed;

-- Check bin coverage per patient
SELECT 
    icustay_id,
    COUNT(hour_offset) as bin_count,
    MIN(hour_offset) as min_offset,
    MAX(hour_offset) as max_offset,
    SUM(ph_imputed_flag) as ph_imputed_bins,
    SUM(magnesium_imputed_flag) as magnesium_imputed_bins,
    SUM(sgpt_imputed_flag) as sgpt_imputed_bins
FROM bloodGasArterial_4bin_imputed
GROUP BY icustay_id
ORDER BY bin_count
LIMIT 10;