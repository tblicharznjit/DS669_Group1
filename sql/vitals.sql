CREATE TABLE vitals_1 AS
SELECT 
  pvt.subject_id,
  pvt.hadm_id,
  pvt.icustay_id,
  pvt.earliestOnset,
  MIN(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate_min,
  MAX(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate_max,
  AVG(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate_mean,
  MIN(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp_min,
  MAX(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp_max,
  AVG(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp_mean,
  MIN(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp_min,
  MAX(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp_max,
  AVG(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp_mean,
  MIN(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_min,
  MAX(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_max,
  AVG(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_mean,
  MIN(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate_min,
  MAX(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate_max,
  AVG(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate_mean,
  MIN(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc_min,
  MAX(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc_max,
  AVG(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc_mean,
  MIN(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2_min,
  MAX(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2_max,
  AVG(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2_mean,
  MIN(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose_min,
  MAX(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose_max,
  AVG(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose_mean
FROM (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    CASE
      WHEN ce.itemid IN (211, 220045) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 1 -- HeartRate
      WHEN ce.itemid IN (51, 442, 455, 6701, 220179, 220050) AND ce.valuenum > 0 AND ce.valuenum < 400 THEN 2 -- SysBP
      WHEN ce.itemid IN (8368, 8440, 8441, 8555, 220180, 220051) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 3 -- DiasBP
      WHEN ce.itemid IN (456, 52, 6702, 443, 220052, 220181, 225312) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 4 -- MeanBP
      WHEN ce.itemid IN (615, 618, 220210, 224690) AND ce.valuenum > 0 AND ce.valuenum < 70 THEN 5 -- RespRate
      WHEN ce.itemid IN (223761, 678) AND ce.valuenum > 70 AND ce.valuenum < 120 THEN 6 -- TempF, converted to degC
      WHEN ce.itemid IN (223762, 676) AND ce.valuenum > 10 AND ce.valuenum < 50 THEN 6 -- TempC
      WHEN ce.itemid IN (646, 220277) AND ce.valuenum > 0 AND ce.valuenum <= 100 THEN 7 -- SpO2
      WHEN ce.itemid IN (807, 811, 1529, 3745, 3744, 225664, 220621, 226537) AND ce.valuenum > 0 THEN 8 -- Glucose
      ELSE NULL
    END AS VitalID,
    CASE 
      WHEN ce.itemid IN (223761, 678) THEN (ce.valuenum - 32) / 1.8 -- Convert Fahrenheit to Celsius
      ELSE ce.valuenum 
    END AS valuenum
  FROM cohort sc
  JOIN icustays ie
    ON sc.subject_id = ie.subject_id
    AND sc.hadm_id = ie.hadm_id
    AND sc.icustay_id = ie.icustay_id
    AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
  LEFT JOIN chartevents ce
    ON ie.icustay_id = ce.icustay_id
    AND ce.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
    AND (ce.error IS NULL OR ce.error = 0)
  WHERE ce.itemid IN (
    211, 220045, -- Heart Rate
    51, 442, 455, 6701, 220179, 220050, -- SysBP
    8368, 8440, 8441, 8555, 220180, 220051, -- DiasBP
    456, 52, 6702, 443, 220052, 220181, 225312, -- MeanBP
    615, 618, 220210, 224690, -- RespRate
    646, 220277, -- SpO2
    807, 811, 1529, 3745, 3744, 225664, 220621, 226537, -- Glucose
    223762, 676, 223761, 678 -- Temperature
  )
) pvt
WHERE pvt.VitalID IS NOT NULL
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.earliestOnset
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;


-- Create vitals in 4-hour bins
DROP TABLE IF EXISTS vitals_4bin;
CREATE TABLE vitals_4bin AS
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    -- Heart Rate (1)
    AVG(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate,
    -- Systolic BP (2)
    AVG(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp,
    -- Diastolic BP (3)
    AVG(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp,
    -- Mean BP (4)
    MIN(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_min,
    AVG(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp,  
    -- Respiratory Rate (5)
    AVG(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate,
    -- Temperature (6)
    AVG(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc,
    -- SpO2 (7)
    AVG(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2,
    -- Glucose (8)
    AVG(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose

FROM 4hr_time_bins tb
LEFT JOIN (
    SELECT 
        ce.subject_id,
        ce.hadm_id,
        ce.icustay_id,
        ce.charttime,
        CASE
            WHEN ce.itemid IN (211, 220045) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 1 -- HeartRate
            WHEN ce.itemid IN (51, 442, 455, 6701, 220179, 220050) AND ce.valuenum > 0 AND ce.valuenum < 400 THEN 2 -- SysBP
            WHEN ce.itemid IN (8368, 8440, 8441, 8555, 220180, 220051) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 3 -- DiasBP
            WHEN ce.itemid IN (456, 52, 6702, 443, 220052, 220181, 225312) AND ce.valuenum > 0 AND ce.valuenum < 300 THEN 4 -- MeanBP
            WHEN ce.itemid IN (615, 618, 220210, 224690) AND ce.valuenum > 0 AND ce.valuenum < 70 THEN 5 -- RespRate
            WHEN ce.itemid IN (223761, 678) AND ce.valuenum > 70 AND ce.valuenum < 120 THEN 6 -- TempF, converted to degC
            WHEN ce.itemid IN (223762, 676) AND ce.valuenum > 10 AND ce.valuenum < 50 THEN 6 -- TempC
            WHEN ce.itemid IN (646, 220277) AND ce.valuenum > 0 AND ce.valuenum <= 100 THEN 7 -- SpO2
            WHEN ce.itemid IN (807, 811, 1529, 3745, 3744, 225664, 220621, 226537) AND ce.valuenum > 0 THEN 8 -- Glucose
            ELSE NULL
        END AS VitalID,
        CASE 
            WHEN ce.itemid IN (223761, 678) THEN (ce.valuenum - 32) / 1.8 -- Convert Fahrenheit to Celsius
            ELSE ce.valuenum 
        END AS valuenum
    FROM ceFiltered ce
    WHERE ce.itemid IN (
        211, 220045, -- Heart Rate
        51, 442, 455, 6701, 220179, 220050, -- SysBP
        8368, 8440, 8441, 8555, 220180, 220051, -- DiasBP
        456, 52, 6702, 443, 220052, 220181, 225312, -- MeanBP
        615, 618, 220210, 224690, -- RespRate
        646, 220277, -- SpO2
        807, 811, 1529, 3745, 3744, 225664, 220621, 226537, -- Glucose
        223762, 676, 223761, 678 -- Temperature
    )
    AND ce.valuenum IS NOT NULL
    AND (ce.error IS NULL OR ce.error = 0)
) pvt
    ON tb.icustay_id = pvt.icustay_id
    AND pvt.charttime >= tb.bin_start_time
    AND pvt.charttime < tb.bin_end_time
    AND pvt.VitalID IS NOT NULL

GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, tb.bin_start_time, tb.bin_end_time
ORDER BY tb.icustay_id, tb.hour_offset;

-- Add indexes for performance
CREATE INDEX idx_vitals_4bin_icustay ON vitals_4bin(icustay_id);
CREATE INDEX idx_vitals_4bin_hour ON vitals_4bin(hour_offset);
CREATE INDEX idx_vitals_4bin_composite ON vitals_4bin(subject_id, hadm_id, icustay_id);


SELECT * FROM vitals_4bin;


-- Create imputed vitals table with multiple fallback strategies
DROP TABLE IF EXISTS vitals_4bin_imputed;
CREATE TABLE vitals_4bin_imputed AS
WITH vital_stats AS (
    -- Calculate patient-level statistics for each vital
    SELECT 
        subject_id,
        hadm_id,
        icustay_id,
        AVG(heartrate) AS patient_mean_hr,
        AVG(sysbp) AS patient_mean_sysbp,
        AVG(diasbp) AS patient_mean_diasbp,
        AVG(meanbp) AS patient_mean_mbp,
        AVG(meanbp_min) AS patient_mean_mbp_min, 
        AVG(resprate) AS patient_mean_rr,
        AVG(tempc) AS patient_mean_temp,
        AVG(spo2) AS patient_mean_spo2,
        AVG(glucose) AS patient_mean_glucose
    FROM vitals_4bin
    WHERE heartrate IS NOT NULL OR sysbp IS NOT NULL OR diasbp IS NOT NULL 
       OR meanbp IS NOT NULL OR resprate IS NOT NULL OR tempc IS NOT NULL 
       OR spo2 IS NOT NULL OR glucose IS NOT NULL
    GROUP BY subject_id, hadm_id, icustay_id
),
population_stats AS (
    -- Calculate population-level normal ranges (clinical defaults)
    SELECT 
        AVG(heartrate) AS pop_mean_hr,
        AVG(sysbp) AS pop_mean_sysbp,
        AVG(diasbp) AS pop_mean_diasbp,
        AVG(meanbp) AS pop_mean_mbp,
        AVG(meanbp_min) AS pop_mean_mbp_min, 
        AVG(resprate) AS pop_mean_rr,
        AVG(tempc) AS pop_mean_temp,
        AVG(spo2) AS pop_mean_spo2,
        AVG(glucose) AS pop_mean_glucose
    FROM vitals_4bin
    WHERE heartrate IS NOT NULL OR sysbp IS NOT NULL OR diasbp IS NOT NULL 
       OR meanbp IS NOT NULL OR resprate IS NOT NULL OR tempc IS NOT NULL 
       OR spo2 IS NOT NULL OR glucose IS NOT NULL
),
forward_filled AS (
    -- Add forward and backward fill
    SELECT 
        v.*,
        -- Forward fill (carry last observation forward)
        LAG(heartrate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_hr,
        LAG(sysbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_sysbp,
        LAG(diasbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_diasbp,
        LAG(meanbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mbp,
        LAG(meanbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mbp_min,
        LAG(resprate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_rr,
        LAG(tempc, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_temp,
        LAG(spo2, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_spo2,
        LAG(glucose, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_glucose,
        -- Backward fill (next observation carried backward)
        LEAD(heartrate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_hr,
        LEAD(sysbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_sysbp,
        LEAD(diasbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_diasbp,
        LEAD(meanbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mbp,
        LEAD(meanbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mbp_min,
        LEAD(resprate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_rr,
        LEAD(tempc, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_temp,
        LEAD(spo2, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_spo2,
        LEAD(glucose, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_glucose
    FROM vitals_4bin v
)
SELECT 
    ff.subject_id,
    ff.hadm_id,
    ff.icustay_id,
    ff.hour_offset,
    ff.bin_start_time,
    ff.bin_end_time,
    -- Heart Rate Imputation (Normal: 60-100 bpm)
    COALESCE(
        ff.heartrate,           -- Original value
        ff.prev_hr,            -- Forward fill
        ff.next_hr,            -- Backward fill
        vs.patient_mean_hr,     -- Patient mean
        ps.pop_mean_hr,         -- Population mean
        80                      -- Clinical default
    ) AS heartrate,
    -- Systolic BP Imputation (Normal: 90-140 mmHg)
    COALESCE(
        ff.sysbp,
        ff.prev_sysbp,
        ff.next_sysbp,
        vs.patient_mean_sysbp,
        ps.pop_mean_sysbp,
        120
    ) AS sysbp,
    -- Diastolic BP Imputation (Normal: 60-90 mmHg)
    COALESCE(
        ff.diasbp,
        ff.prev_diasbp,
        ff.next_diasbp,
        vs.patient_mean_diasbp,
        ps.pop_mean_diasbp,
        80
    ) AS diasbp,
    -- Mean BP Imputation (Normal: 70-105 mmHg)
    COALESCE(
        ff.meanbp,
        ff.prev_mbp,
        ff.next_mbp,
        vs.patient_mean_mbp,
        ps.pop_mean_mbp,
        90
    ) AS meanbp,
     -- Mean BP Min Imputation (Normal: 65-95 mmHg) - Added this
    COALESCE(
        ff.meanbp_min,
        ff.prev_mbp_min,
        ff.next_mbp_min,
        vs.patient_mean_mbp_min,
        ps.pop_mean_mbp_min,
        85                      -- Clinical default (slightly lower than mean)
    ) AS meanbp_min,
    -- Respiratory Rate Imputation (Normal: 12-20 /min)
    COALESCE(
        ff.resprate,
        ff.prev_rr,
        ff.next_rr,
        vs.patient_mean_rr,
        ps.pop_mean_rr,
        16
    ) AS resprate,
    -- Temperature Imputation (Normal: 36.5-37.5°C)
    COALESCE(
        ff.tempc,
        ff.prev_temp,
        ff.next_temp,
        vs.patient_mean_temp,
        ps.pop_mean_temp,
        37.0
    ) AS tempc,
    -- SpO2 Imputation (Normal: 95-100%)
    COALESCE(
        ff.spo2,
        ff.prev_spo2,
        ff.next_spo2,
        vs.patient_mean_spo2,
        ps.pop_mean_spo2,
        98
    ) AS spo2,
    -- Glucose Imputation (Normal: 70-140 mg/dL)
    COALESCE(
        ff.glucose,
        ff.prev_glucose,
        ff.next_glucose,
        vs.patient_mean_glucose,
        ps.pop_mean_glucose,
        120
    ) AS glucose,
    -- Add imputation flags for tracking
    CASE WHEN ff.heartrate IS NULL THEN 1 ELSE 0 END AS heartrate_imputed,
    CASE WHEN ff.sysbp IS NULL THEN 1 ELSE 0 END AS sysbp_imputed,
    CASE WHEN ff.diasbp IS NULL THEN 1 ELSE 0 END AS diasbp_imputed,
    CASE WHEN ff.meanbp IS NULL THEN 1 ELSE 0 END AS meanbp_imputed,
    CASE WHEN ff.meanbp_min IS NULL THEN 1 ELSE 0 END AS meanbp_min_imputed, 
    CASE WHEN ff.resprate IS NULL THEN 1 ELSE 0 END AS resprate_imputed,
    CASE WHEN ff.tempc IS NULL THEN 1 ELSE 0 END AS tempc_imputed,
    CASE WHEN ff.spo2 IS NULL THEN 1 ELSE 0 END AS spo2_imputed,
    CASE WHEN ff.glucose IS NULL THEN 1 ELSE 0 END AS glucose_imputed

FROM forward_filled ff
LEFT JOIN vital_stats vs
    ON ff.subject_id = vs.subject_id
    AND ff.hadm_id = vs.hadm_id
    AND ff.icustay_id = vs.icustay_id
CROSS JOIN population_stats ps
ORDER BY ff.icustay_id, ff.hour_offset;

-- Add indexes
CREATE INDEX idx_vitals_imputed_icustay ON vitals_4bin_imputed(icustay_id);
CREATE INDEX idx_vitals_imputed_hour ON vitals_4bin_imputed(hour_offset);
CREATE INDEX idx_vitals_imputed_composite ON vitals_4bin_imputed(subject_id, hadm_id, icustay_id);


SELECT AVG(heartrate), AVG(spo2), AVG(resprate), AVG(meanbp), AVG(diasbp), AVG(sysbp), AVG(tempc), AVG(glucose/18.0182) FROM vitals_4bin_imputed;

ALTER TABLE vitals_4bin_imputed DROP COLUMN glucose, DROP COLUMN glucose_imputed;

SELECT * from demographics_imputed d JOIN vitals_4bin_imputed v 
on v.subject_id = d.subject_id 
AND v.hadm_id = d.hadm_id
AND v.icustay_id = d.icustay_id
ANd d.hour_offset = v.hour_offset;

SELECT * FROM vitals_4bin_imputed;