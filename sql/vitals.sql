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


-- Create vitals in 4-hour bins with min, max, and avg values
DROP TABLE IF EXISTS vitals_4bin;
CREATE TABLE vitals_4bin AS
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    -- Heart Rate (1) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate_min,
    MAX(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate_max,
    AVG(CASE WHEN pvt.VitalID = 1 THEN pvt.valuenum ELSE NULL END) AS heartrate,
    -- Systolic BP (2) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp_min,
    MAX(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp_max,
    AVG(CASE WHEN pvt.VitalID = 2 THEN pvt.valuenum ELSE NULL END) AS sysbp,
    -- Diastolic BP (3) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp_min,
    MAX(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp_max,
    AVG(CASE WHEN pvt.VitalID = 3 THEN pvt.valuenum ELSE NULL END) AS diasbp,
    -- Mean BP (4) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_min,
    MAX(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp_max,
    AVG(CASE WHEN pvt.VitalID = 4 THEN pvt.valuenum ELSE NULL END) AS meanbp,  
    -- Respiratory Rate (5) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate_min,
    MAX(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate_max,
    AVG(CASE WHEN pvt.VitalID = 5 THEN pvt.valuenum ELSE NULL END) AS resprate,
    -- Temperature (6) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc_min,
    MAX(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc_max,
    AVG(CASE WHEN pvt.VitalID = 6 THEN pvt.valuenum ELSE NULL END) AS tempc,
    -- SpO2 (7) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2_min,
    MAX(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2_max,
    AVG(CASE WHEN pvt.VitalID = 7 THEN pvt.valuenum ELSE NULL END) AS spo2,
    -- Glucose (8) - Min, Max, Avg
    MIN(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose_min,
    MAX(CASE WHEN pvt.VitalID = 8 THEN pvt.valuenum ELSE NULL END) AS glucose_max,
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

-- imputed vitals table with multiple fallback strategies for all min/max/avg values
DROP TABLE IF EXISTS vitals_4bin_imputed;
CREATE TABLE vitals_4bin_imputed AS
WITH vital_stats AS (
    -- patient-level statistics for each vital (min, max, avg)
    SELECT 
        subject_id,
        hadm_id,
        icustay_id,
        AVG(heartrate_min) AS patient_mean_hr_min,
        AVG(heartrate_max) AS patient_mean_hr_max,
        AVG(heartrate) AS patient_mean_hr,
        AVG(sysbp_min) AS patient_mean_sysbp_min,
        AVG(sysbp_max) AS patient_mean_sysbp_max,
        AVG(sysbp) AS patient_mean_sysbp,
        AVG(diasbp_min) AS patient_mean_diasbp_min,
        AVG(diasbp_max) AS patient_mean_diasbp_max,
        AVG(diasbp) AS patient_mean_diasbp,
        AVG(meanbp_min) AS patient_mean_mbp_min,
        AVG(meanbp_max) AS patient_mean_mbp_max,
        AVG(meanbp) AS patient_mean_mbp,
        AVG(resprate_min) AS patient_mean_rr_min,
        AVG(resprate_max) AS patient_mean_rr_max,
        AVG(resprate) AS patient_mean_rr,
        AVG(tempc_min) AS patient_mean_temp_min,
        AVG(tempc_max) AS patient_mean_temp_max,
        AVG(tempc) AS patient_mean_temp,
        AVG(spo2_min) AS patient_mean_spo2_min,
        AVG(spo2_max) AS patient_mean_spo2_max,
        AVG(spo2) AS patient_mean_spo2,
        AVG(glucose_min) AS patient_mean_glucose_min,
        AVG(glucose_max) AS patient_mean_glucose_max,
        AVG(glucose) AS patient_mean_glucose
    FROM vitals_4bin
    WHERE heartrate IS NOT NULL OR sysbp IS NOT NULL OR diasbp IS NOT NULL 
       OR meanbp IS NOT NULL OR resprate IS NOT NULL OR tempc IS NOT NULL 
       OR spo2 IS NOT NULL OR glucose IS NOT NULL
    GROUP BY subject_id, hadm_id, icustay_id
),
population_stats AS (
    -- Calculate population-level statistics for all vitals
    SELECT 
        AVG(heartrate_min) AS pop_mean_hr_min,
        AVG(heartrate_max) AS pop_mean_hr_max,
        AVG(heartrate) AS pop_mean_hr,
        AVG(sysbp_min) AS pop_mean_sysbp_min,
        AVG(sysbp_max) AS pop_mean_sysbp_max,
        AVG(sysbp) AS pop_mean_sysbp,
        AVG(diasbp_min) AS pop_mean_diasbp_min,
        AVG(diasbp_max) AS pop_mean_diasbp_max,
        AVG(diasbp) AS pop_mean_diasbp,
        AVG(meanbp_min) AS pop_mean_mbp_min,
        AVG(meanbp_max) AS pop_mean_mbp_max,
        AVG(meanbp) AS pop_mean_mbp,
        AVG(resprate_min) AS pop_mean_rr_min,
        AVG(resprate_max) AS pop_mean_rr_max,
        AVG(resprate) AS pop_mean_rr,
        AVG(tempc_min) AS pop_mean_temp_min,
        AVG(tempc_max) AS pop_mean_temp_max,
        AVG(tempc) AS pop_mean_temp,
        AVG(spo2_min) AS pop_mean_spo2_min,
        AVG(spo2_max) AS pop_mean_spo2_max,
        AVG(spo2) AS pop_mean_spo2,
        AVG(glucose_min) AS pop_mean_glucose_min,
        AVG(glucose_max) AS pop_mean_glucose_max,
        AVG(glucose) AS pop_mean_glucose
    FROM vitals_4bin
    WHERE heartrate IS NOT NULL OR sysbp IS NOT NULL OR diasbp IS NOT NULL 
       OR meanbp IS NOT NULL OR resprate IS NOT NULL OR tempc IS NOT NULL 
       OR spo2 IS NOT NULL OR glucose IS NOT NULL
),
forward_filled AS (
    -- Add forward and backward fill for all values
    SELECT 
        v.*,
        -- Forward fill (carry last observation forward) for all values
        LAG(heartrate_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_hr_min,
        LAG(heartrate_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_hr_max,
        LAG(heartrate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_hr,
        LAG(sysbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_sysbp_min,
        LAG(sysbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_sysbp_max,
        LAG(sysbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_sysbp,
        LAG(diasbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_diasbp_min,
        LAG(diasbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_diasbp_max,
        LAG(diasbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_diasbp,
        LAG(meanbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mbp_min,
        LAG(meanbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mbp_max,
        LAG(meanbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mbp,
        LAG(resprate_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_rr_min,
        LAG(resprate_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_rr_max,
        LAG(resprate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_rr,
        LAG(tempc_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_temp_min,
        LAG(tempc_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_temp_max,
        LAG(tempc, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_temp,
        LAG(spo2_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_spo2_min,
        LAG(spo2_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_spo2_max,
        LAG(spo2, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_spo2,
        LAG(glucose_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_glucose_min,
        LAG(glucose_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_glucose_max,
        LAG(glucose, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_glucose,
        -- Backward fill (next observation carried backward) for all values
        LEAD(heartrate_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_hr_min,
        LEAD(heartrate_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_hr_max,
        LEAD(heartrate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_hr,
        LEAD(sysbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_sysbp_min,
        LEAD(sysbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_sysbp_max,
        LEAD(sysbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_sysbp,
        LEAD(diasbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_diasbp_min,
        LEAD(diasbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_diasbp_max,
        LEAD(diasbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_diasbp,
        LEAD(meanbp_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mbp_min,
        LEAD(meanbp_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mbp_max,
        LEAD(meanbp, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mbp,
        LEAD(resprate_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_rr_min,
        LEAD(resprate_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_rr_max,
        LEAD(resprate, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_rr,
        LEAD(tempc_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_temp_min,
        LEAD(tempc_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_temp_max,
        LEAD(tempc, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_temp,
        LEAD(spo2_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_spo2_min,
        LEAD(spo2_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_spo2_max,
        LEAD(spo2, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_spo2,
        LEAD(glucose_min, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_glucose_min,
        LEAD(glucose_max, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_glucose_max,
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
    COALESCE(ff.heartrate_min, ff.prev_hr_min, ff.next_hr_min, vs.patient_mean_hr_min, ps.pop_mean_hr_min, 70) AS heartrate_min,
    COALESCE(ff.heartrate_max, ff.prev_hr_max, ff.next_hr_max, vs.patient_mean_hr_max, ps.pop_mean_hr_max, 90) AS heartrate_max,
    COALESCE(ff.heartrate, ff.prev_hr, ff.next_hr, vs.patient_mean_hr, ps.pop_mean_hr, 80) AS heartrate,
    -- Systolic BP Imputation (Normal: 90-140 mmHg)
    COALESCE(ff.sysbp_min, ff.prev_sysbp_min, ff.next_sysbp_min, vs.patient_mean_sysbp_min, ps.pop_mean_sysbp_min, 110) AS sysbp_min,
    COALESCE(ff.sysbp_max, ff.prev_sysbp_max, ff.next_sysbp_max, vs.patient_mean_sysbp_max, ps.pop_mean_sysbp_max, 130) AS sysbp_max,
    COALESCE(ff.sysbp, ff.prev_sysbp, ff.next_sysbp, vs.patient_mean_sysbp, ps.pop_mean_sysbp, 120) AS sysbp,
    -- Diastolic BP Imputation (Normal: 60-90 mmHg)
    COALESCE(ff.diasbp_min, ff.prev_diasbp_min, ff.next_diasbp_min, vs.patient_mean_diasbp_min, ps.pop_mean_diasbp_min, 70) AS diasbp_min,
    COALESCE(ff.diasbp_max, ff.prev_diasbp_max, ff.next_diasbp_max, vs.patient_mean_diasbp_max, ps.pop_mean_diasbp_max, 90) AS diasbp_max,
    COALESCE(ff.diasbp, ff.prev_diasbp, ff.next_diasbp, vs.patient_mean_diasbp, ps.pop_mean_diasbp, 80) AS diasbp,
    -- Mean BP Imputation (Normal: 70-105 mmHg)
    COALESCE(ff.meanbp_min, ff.prev_mbp_min, ff.next_mbp_min, vs.patient_mean_mbp_min, ps.pop_mean_mbp_min, 80) AS meanbp_min,
    COALESCE(ff.meanbp_max, ff.prev_mbp_max, ff.next_mbp_max, vs.patient_mean_mbp_max, ps.pop_mean_mbp_max, 100) AS meanbp_max,
    COALESCE(ff.meanbp, ff.prev_mbp, ff.next_mbp, vs.patient_mean_mbp, ps.pop_mean_mbp, 90) AS meanbp,
    -- Respiratory Rate Imputation (Normal: 12-20 /min)
    COALESCE(ff.resprate_min, ff.prev_rr_min, ff.next_rr_min, vs.patient_mean_rr_min, ps.pop_mean_rr_min, 14) AS resprate_min,
    COALESCE(ff.resprate_max, ff.prev_rr_max, ff.next_rr_max, vs.patient_mean_rr_max, ps.pop_mean_rr_max, 18) AS resprate_max,
    COALESCE(ff.resprate, ff.prev_rr, ff.next_rr, vs.patient_mean_rr, ps.pop_mean_rr, 16) AS resprate,
    -- Temperature Imputation (Normal: 36.5-37.5°C)
    COALESCE(ff.tempc_min, ff.prev_temp_min, ff.next_temp_min, vs.patient_mean_temp_min, ps.pop_mean_temp_min, 36.5) AS tempc_min,
    COALESCE(ff.tempc_max, ff.prev_temp_max, ff.next_temp_max, vs.patient_mean_temp_max, ps.pop_mean_temp_max, 37.5) AS tempc_max,
    COALESCE(ff.tempc, ff.prev_temp, ff.next_temp, vs.patient_mean_temp, ps.pop_mean_temp, 37.0) AS tempc,
    -- SpO2 Imputation (Normal: 95-100%)
    COALESCE(ff.spo2_min, ff.prev_spo2_min, ff.next_spo2_min, vs.patient_mean_spo2_min, ps.pop_mean_spo2_min, 96) AS spo2_min,
    COALESCE(ff.spo2_max, ff.prev_spo2_max, ff.next_spo2_max, vs.patient_mean_spo2_max, ps.pop_mean_spo2_max, 100) AS spo2_max,
    COALESCE(ff.spo2, ff.prev_spo2, ff.next_spo2, vs.patient_mean_spo2, ps.pop_mean_spo2, 98) AS spo2,
    -- Glucose Imputation (Normal: 70-140 mg/dL) - Keep for backward compatibility
    COALESCE(ff.glucose_min, ff.prev_glucose_min, ff.next_glucose_min, vs.patient_mean_glucose_min, ps.pop_mean_glucose_min, 100) AS glucose_min,
    COALESCE(ff.glucose_max, ff.prev_glucose_max, ff.next_glucose_max, vs.patient_mean_glucose_max, ps.pop_mean_glucose_max, 140) AS glucose_max,
    COALESCE(ff.glucose, ff.prev_glucose, ff.next_glucose, vs.patient_mean_glucose, ps.pop_mean_glucose, 120) AS glucose,
    -- Add imputation flags for tracking (avg values only for brevity)
    CASE WHEN ff.heartrate IS NULL THEN 1 ELSE 0 END AS heartrate_imputed,
    CASE WHEN ff.sysbp IS NULL THEN 1 ELSE 0 END AS sysbp_imputed,
    CASE WHEN ff.diasbp IS NULL THEN 1 ELSE 0 END AS diasbp_imputed,
    CASE WHEN ff.meanbp IS NULL THEN 1 ELSE 0 END AS meanbp_imputed,
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

-- Display summary statistics
SELECT AVG(heartrate), AVG(spo2), AVG(resprate), AVG(meanbp), AVG(diasbp), AVG(sysbp), AVG(tempc), AVG(glucose/18.0182) FROM vitals_4bin_imputed;

SELECT * FROM vitals_4bin_imputed;


ALTER TABLE vitals_4bin_imputed 
ADD COLUMN shock_index DECIMAL(5,3),
ADD COLUMN shock_index_min DECIMAL(5,3),
ADD COLUMN shock_index_max DECIMAL(5,3);

-- Calculate shock index (HR/SBP ratio)
UPDATE vitals_4bin_imputed 
SET 
    shock_index = CASE 
        WHEN sysbp > 30 THEN LEAST(heartrate / sysbp, 5.0)  -- Cap at 5.0 to prevent overflow
        ELSE NULL 
    END,
    shock_index_min = CASE 
        WHEN sysbp_max > 30 THEN LEAST(heartrate_min / sysbp_max, 5.0)
        ELSE NULL 
    END,
    shock_index_max = CASE 
        WHEN sysbp_min > 30 THEN LEAST(heartrate_max / sysbp_min, 5.0)
        ELSE NULL 
    END;

SELECT AVG(shock_index) FROM vitals_4bin_imputed;



ALTER TABLE vitals_4bin 
ADD COLUMN shock_index DECIMAL(5,3),
ADD COLUMN shock_index_min DECIMAL(5,3),
ADD COLUMN shock_index_max DECIMAL(5,3);

-- Calculate shock index (HR/SBP ratio)
UPDATE vitals_4bin 
SET 
    shock_index = CASE 
        WHEN sysbp > 30 THEN LEAST(heartrate / sysbp, 5.0)  -- Cap at 5.0 to prevent overflow
        ELSE NULL 
    END,
    shock_index_min = CASE 
        WHEN sysbp_max > 30 THEN LEAST(heartrate_min / sysbp_max, 5.0)
        ELSE NULL 
    END,
    shock_index_max = CASE 
        WHEN sysbp_min > 30 THEN LEAST(heartrate_max / sysbp_min, 5.0)
        ELSE NULL 
    END;

SELECT AVG(shock_index) FROM vitals_4bin;