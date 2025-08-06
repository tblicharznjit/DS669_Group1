
CREATE TABLE labVals_1 AS
SELECT
  pvt.subject_id,
  pvt.hadm_id,
  pvt.icustay_id,
  pvt.earliestOnset,
  MIN(CASE WHEN pvt.label = 'ANION GAP' THEN pvt.valuenum ELSE NULL END) AS aniongap_min,
  MAX(CASE WHEN pvt.label = 'ANION GAP' THEN pvt.valuenum ELSE NULL END) AS aniongap_max,
  MIN(CASE WHEN pvt.label = 'ALBUMIN' THEN pvt.valuenum ELSE NULL END) AS albumin_min,
  MAX(CASE WHEN pvt.label = 'ALBUMIN' THEN pvt.valuenum ELSE NULL END) AS albumin_max,
  MIN(CASE WHEN pvt.label = 'BANDS' THEN pvt.valuenum ELSE NULL END) AS bands_min,
  MAX(CASE WHEN pvt.label = 'BANDS' THEN pvt.valuenum ELSE NULL END) AS bands_max,
  MIN(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate_min,
  MAX(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate_max,
  MIN(CASE WHEN pvt.label = 'BILIRUBIN' THEN pvt.valuenum ELSE NULL END) AS bilirubin_min,
  MAX(CASE WHEN pvt.label = 'BILIRUBIN' THEN pvt.valuenum ELSE NULL END) AS bilirubin_max,
  MIN(CASE WHEN pvt.label = 'CREATININE' THEN pvt.valuenum ELSE NULL END) AS creatinine_min,
  MAX(CASE WHEN pvt.label = 'CREATININE' THEN pvt.valuenum ELSE NULL END) AS creatinine_max,
  MIN(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride_min,
  MAX(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride_max,
  MIN(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose_min,
  MAX(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose_max,
  MIN(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit_min,
  MAX(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit_max,
  MIN(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin_min,
  MAX(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin_max,
  MIN(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate_min,
  MAX(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate_max,
  MIN(CASE WHEN pvt.label = 'PLATELET' THEN pvt.valuenum ELSE NULL END) AS platelet_min,
  MAX(CASE WHEN pvt.label = 'PLATELET' THEN pvt.valuenum ELSE NULL END) AS platelet_max,
  MIN(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium_min,
  MAX(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium_max,
  MIN(CASE WHEN pvt.label = 'PTT' THEN pvt.valuenum ELSE NULL END) AS ptt_min,
  MAX(CASE WHEN pvt.label = 'PTT' THEN pvt.valuenum ELSE NULL END) AS ptt_max,
  MIN(CASE WHEN pvt.label = 'INR' THEN pvt.valuenum ELSE NULL END) AS inr_min,
  MAX(CASE WHEN pvt.label = 'INR' THEN pvt.valuenum ELSE NULL END) AS inr_max,
  MIN(CASE WHEN pvt.label = 'PT' THEN pvt.valuenum ELSE NULL END) AS pt_min,
  MAX(CASE WHEN pvt.label = 'PT' THEN pvt.valuenum ELSE NULL END) AS pt_max,
  MIN(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium_min,
  MAX(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium_max,
  MIN(CASE WHEN pvt.label = 'BUN' THEN pvt.valuenum ELSE NULL END) AS bun_min,
  MAX(CASE WHEN pvt.label = 'BUN' THEN pvt.valuenum ELSE NULL END) AS bun_max,
  MIN(CASE WHEN pvt.label = 'WBC' THEN pvt.valuenum ELSE NULL END) AS wbc_min,
  MAX(CASE WHEN pvt.label = 'WBC' THEN pvt.valuenum ELSE NULL END) AS wbc_max
FROM (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    CASE
      WHEN le.itemid = 50868 THEN 'ANION GAP'
      WHEN le.itemid = 50862 THEN 'ALBUMIN'
      WHEN le.itemid = 51144 THEN 'BANDS'
      WHEN le.itemid = 50882 THEN 'BICARBONATE'
      WHEN le.itemid = 50885 THEN 'BILIRUBIN'
      WHEN le.itemid = 50912 THEN 'CREATININE'
      WHEN le.itemid IN (50806, 50902) THEN 'CHLORIDE'
      WHEN le.itemid IN (50809, 50931) THEN 'GLUCOSE'
      WHEN le.itemid IN (50810, 51221) THEN 'HEMATOCRIT'
      WHEN le.itemid IN (50811, 51222) THEN 'HEMOGLOBIN'
      WHEN le.itemid = 50813 THEN 'LACTATE'
      WHEN le.itemid = 51265 THEN 'PLATELET'
      WHEN le.itemid IN (50822, 50971) THEN 'POTASSIUM'
      WHEN le.itemid = 51275 THEN 'PTT'
      WHEN le.itemid = 51237 THEN 'INR'
      WHEN le.itemid = 51274 THEN 'PT'
      WHEN le.itemid IN (50824, 50983) THEN 'SODIUM'
      WHEN le.itemid = 51006 THEN 'BUN'
      WHEN le.itemid IN (51300, 51301) THEN 'WBC'
      ELSE NULL
    END AS label,
    CASE
      WHEN le.itemid = 50862 AND le.valuenum > 10 THEN NULL -- ALBUMIN
      WHEN le.itemid = 50868 AND le.valuenum > 10000 THEN NULL -- ANION GAP
      WHEN le.itemid = 51144 AND (le.valuenum < 0 OR le.valuenum > 100) THEN NULL -- BANDS
      WHEN le.itemid = 50882 AND le.valuenum > 10000 THEN NULL -- BICARBONATE
      WHEN le.itemid = 50885 AND le.valuenum > 150 THEN NULL -- BILIRUBIN
      WHEN le.itemid IN (50806, 50902) AND le.valuenum > 10000 THEN NULL -- CHLORIDE
      WHEN le.itemid = 50912 AND le.valuenum > 150 THEN NULL -- CREATININE
      WHEN le.itemid IN (50809, 50931) AND le.valuenum > 10000 THEN NULL -- GLUCOSE
      WHEN le.itemid IN (50810, 51221) AND le.valuenum > 100 THEN NULL -- HEMATOCRIT
      WHEN le.itemid IN (50811, 51222) AND le.valuenum > 50 THEN NULL -- HEMOGLOBIN
      WHEN le.itemid = 50813 AND le.valuenum > 50 THEN NULL -- LACTATE
      WHEN le.itemid = 51265 AND le.valuenum > 10000 THEN NULL -- PLATELET
      WHEN le.itemid IN (50822, 50971) AND le.valuenum > 30 THEN NULL -- POTASSIUM
      WHEN le.itemid = 51275 AND le.valuenum > 150 THEN NULL -- PTT
      WHEN le.itemid = 51237 AND le.valuenum > 50 THEN NULL -- INR
      WHEN le.itemid = 51274 AND le.valuenum > 150 THEN NULL -- PT
      WHEN le.itemid IN (50824, 50983) AND le.valuenum > 200 THEN NULL -- SODIUM
      WHEN le.itemid = 51006 AND le.valuenum > 300 THEN NULL -- BUN
      WHEN le.itemid IN (51300, 51301) AND le.valuenum > 1000 THEN NULL -- WBC
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
    AND le.charttime BETWEEN (DATE_SUB(sc.earliestOnset, INTERVAL '6' HOUR)) AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
    AND le.itemid IN (
      50868, 50862, 51144, 50882, 50885, 50912, 50806, 50902, 50809, 50931,
      50810, 51221, 50811, 51222, 50813, 51265, 50822, 50971, 51275, 51237,
      51274, 50824, 50983, 51006, 51300, 51301
    )
    AND le.valuenum IS NOT NULL
    AND le.valuenum > 0
) pvt
WHERE pvt.label IS NOT NULL
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.earliestOnset
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;




-- Create lab values in 4-hour bins
DROP TABLE IF EXISTS labVals_4bin;
CREATE TABLE labVals_4bin AS
SELECT
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  -- Anion Gap
  MIN(CASE WHEN pvt.label = 'ANION GAP' THEN pvt.valuenum ELSE NULL END) AS aniongap_min,
  MAX(CASE WHEN pvt.label = 'ANION GAP' THEN pvt.valuenum ELSE NULL END) AS aniongap_max,
  AVG(CASE WHEN pvt.label = 'ANION GAP' THEN pvt.valuenum ELSE NULL END) AS aniongap_avg,
  -- Albumin
  MIN(CASE WHEN pvt.label = 'ALBUMIN' THEN pvt.valuenum ELSE NULL END) AS albumin_min,
  MAX(CASE WHEN pvt.label = 'ALBUMIN' THEN pvt.valuenum ELSE NULL END) AS albumin_max,
  AVG(CASE WHEN pvt.label = 'ALBUMIN' THEN pvt.valuenum ELSE NULL END) AS albumin_avg,
  -- Bands
  MIN(CASE WHEN pvt.label = 'BANDS' THEN pvt.valuenum ELSE NULL END) AS bands_min,
  MAX(CASE WHEN pvt.label = 'BANDS' THEN pvt.valuenum ELSE NULL END) AS bands_max,
  AVG(CASE WHEN pvt.label = 'BANDS' THEN pvt.valuenum ELSE NULL END) AS bands_avg,
  -- Bicarbonate
  MIN(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate_min,
  MAX(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate_max,
  AVG(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate_avg,
  -- Bilirubin
  MIN(CASE WHEN pvt.label = 'BILIRUBIN' THEN pvt.valuenum ELSE NULL END) AS bilirubin_min,
  MAX(CASE WHEN pvt.label = 'BILIRUBIN' THEN pvt.valuenum ELSE NULL END) AS bilirubin_max,
  AVG(CASE WHEN pvt.label = 'BILIRUBIN' THEN pvt.valuenum ELSE NULL END) AS bilirubin_avg,
  -- Creatinine
  MIN(CASE WHEN pvt.label = 'CREATININE' THEN pvt.valuenum ELSE NULL END) AS creatinine_min,
  MAX(CASE WHEN pvt.label = 'CREATININE' THEN pvt.valuenum ELSE NULL END) AS creatinine_max,
  AVG(CASE WHEN pvt.label = 'CREATININE' THEN pvt.valuenum ELSE NULL END) AS creatinine_avg,
  -- Chloride
  MIN(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride_min,
  MAX(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride_max,
  AVG(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride_avg,
  -- Glucose
  MIN(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose_min,
  MAX(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose_max,
  AVG(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose_avg,
  -- Hematocrit
  MIN(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit_min,
  MAX(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit_max,
  AVG(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit_avg,
  -- Hemoglobin
  MIN(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin_min,
  MAX(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin_max,
  AVG(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin_avg,
  -- Lactate
  MIN(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate_min,
  MAX(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate_max,
  AVG(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate_avg,
  -- Platelet
  MIN(CASE WHEN pvt.label = 'PLATELET' THEN pvt.valuenum ELSE NULL END) AS platelet_min,
  MAX(CASE WHEN pvt.label = 'PLATELET' THEN pvt.valuenum ELSE NULL END) AS platelet_max,
  AVG(CASE WHEN pvt.label = 'PLATELET' THEN pvt.valuenum ELSE NULL END) AS platelet_avg,
  -- Potassium
  MIN(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium_min,
  MAX(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium_max,
  AVG(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium_avg,
  -- PTT
  MIN(CASE WHEN pvt.label = 'PTT' THEN pvt.valuenum ELSE NULL END) AS ptt_min,
  MAX(CASE WHEN pvt.label = 'PTT' THEN pvt.valuenum ELSE NULL END) AS ptt_max,
  AVG(CASE WHEN pvt.label = 'PTT' THEN pvt.valuenum ELSE NULL END) AS ptt_avg,
  -- INR
  MIN(CASE WHEN pvt.label = 'INR' THEN pvt.valuenum ELSE NULL END) AS inr_min,
  MAX(CASE WHEN pvt.label = 'INR' THEN pvt.valuenum ELSE NULL END) AS inr_max,
  AVG(CASE WHEN pvt.label = 'INR' THEN pvt.valuenum ELSE NULL END) AS inr_avg,
  -- PT
  MIN(CASE WHEN pvt.label = 'PT' THEN pvt.valuenum ELSE NULL END) AS pt_min,
  MAX(CASE WHEN pvt.label = 'PT' THEN pvt.valuenum ELSE NULL END) AS pt_max,
  AVG(CASE WHEN pvt.label = 'PT' THEN pvt.valuenum ELSE NULL END) AS pt_avg,
  -- Sodium
  MIN(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium_min,
  MAX(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium_max,
  AVG(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium_avg,
  -- BUN
  MIN(CASE WHEN pvt.label = 'BUN' THEN pvt.valuenum ELSE NULL END) AS bun_min,
  MAX(CASE WHEN pvt.label = 'BUN' THEN pvt.valuenum ELSE NULL END) AS bun_max,
  AVG(CASE WHEN pvt.label = 'BUN' THEN pvt.valuenum ELSE NULL END) AS bun_avg,
  -- WBC
  MIN(CASE WHEN pvt.label = 'WBC' THEN pvt.valuenum ELSE NULL END) AS wbc_min,
  MAX(CASE WHEN pvt.label = 'WBC' THEN pvt.valuenum ELSE NULL END) AS wbc_max,
  AVG(CASE WHEN pvt.label = 'WBC' THEN pvt.valuenum ELSE NULL END) AS wbc_avg,
  -- Measurement counts for data quality tracking
  COUNT(CASE WHEN pvt.label = 'LACTATE' THEN 1 END) AS lactate_measurements,
  COUNT(CASE WHEN pvt.label = 'CREATININE' THEN 1 END) AS creatinine_measurements,
  COUNT(CASE WHEN pvt.label = 'BILIRUBIN' THEN 1 END) AS bilirubin_measurements,
  COUNT(CASE WHEN pvt.label = 'PLATELET' THEN 1 END) AS platelet_measurements,
  COUNT(CASE WHEN pvt.label = 'WBC' THEN 1 END) AS wbc_measurements

FROM 4hr_time_bins tb
LEFT JOIN (
  SELECT 
    le.subject_id,
    le.hadm_id,
    le.charttime,
    CASE
      WHEN le.itemid = 50868 THEN 'ANION GAP'
      WHEN le.itemid = 50862 THEN 'ALBUMIN'
      WHEN le.itemid = 51144 THEN 'BANDS'
      WHEN le.itemid = 50882 THEN 'BICARBONATE'
      WHEN le.itemid = 50885 THEN 'BILIRUBIN'
      WHEN le.itemid = 50912 THEN 'CREATININE'
      WHEN le.itemid IN (50806, 50902) THEN 'CHLORIDE'
      WHEN le.itemid IN (50809, 50931) THEN 'GLUCOSE'
      WHEN le.itemid IN (50810, 51221) THEN 'HEMATOCRIT'
      WHEN le.itemid IN (50811, 51222) THEN 'HEMOGLOBIN'
      WHEN le.itemid = 50813 THEN 'LACTATE'
      WHEN le.itemid = 51265 THEN 'PLATELET'
      WHEN le.itemid IN (50822, 50971) THEN 'POTASSIUM'
      WHEN le.itemid = 51275 THEN 'PTT'
      WHEN le.itemid = 51237 THEN 'INR'
      WHEN le.itemid = 51274 THEN 'PT'
      WHEN le.itemid IN (50824, 50983) THEN 'SODIUM'
      WHEN le.itemid = 51006 THEN 'BUN'
      WHEN le.itemid IN (51300, 51301) THEN 'WBC'
      ELSE NULL
    END AS label,
    CASE
      WHEN le.itemid = 50862 AND le.valuenum > 10 THEN NULL -- ALBUMIN
      WHEN le.itemid = 50868 AND le.valuenum > 10000 THEN NULL -- ANION GAP
      WHEN le.itemid = 51144 AND (le.valuenum < 0 OR le.valuenum > 100) THEN NULL -- BANDS
      WHEN le.itemid = 50882 AND le.valuenum > 10000 THEN NULL -- BICARBONATE
      WHEN le.itemid = 50885 AND le.valuenum > 150 THEN NULL -- BILIRUBIN
      WHEN le.itemid IN (50806, 50902) AND le.valuenum > 10000 THEN NULL -- CHLORIDE
      WHEN le.itemid = 50912 AND le.valuenum > 150 THEN NULL -- CREATININE
      WHEN le.itemid IN (50809, 50931) AND le.valuenum > 10000 THEN NULL -- GLUCOSE
      WHEN le.itemid IN (50810, 51221) AND le.valuenum > 100 THEN NULL -- HEMATOCRIT
      WHEN le.itemid IN (50811, 51222) AND le.valuenum > 50 THEN NULL -- HEMOGLOBIN
      WHEN le.itemid = 50813 AND le.valuenum > 50 THEN NULL -- LACTATE
      WHEN le.itemid = 51265 AND le.valuenum > 10000 THEN NULL -- PLATELET
      WHEN le.itemid IN (50822, 50971) AND le.valuenum > 30 THEN NULL -- POTASSIUM
      WHEN le.itemid = 51275 AND le.valuenum > 150 THEN NULL -- PTT
      WHEN le.itemid = 51237 AND le.valuenum > 50 THEN NULL -- INR
      WHEN le.itemid = 51274 AND le.valuenum > 150 THEN NULL -- PT
      WHEN le.itemid IN (50824, 50983) AND le.valuenum > 200 THEN NULL -- SODIUM
      WHEN le.itemid = 51006 AND le.valuenum > 300 THEN NULL -- BUN
      WHEN le.itemid IN (51300, 51301) AND le.valuenum > 1000 THEN NULL -- WBC
      ELSE le.valuenum
    END AS valuenum
  FROM labevents le
  WHERE le.itemid IN (
    50868, 50862, 51144, 50882, 50885, 50912, 50806, 50902, 50809, 50931,
    50810, 51221, 50811, 51222, 50813, 51265, 50822, 50971, 51275, 51237,
    51274, 50824, 50983, 51006, 51300, 51301
  )
  AND le.valuenum IS NOT NULL
  AND le.valuenum > 0
) pvt
  ON tb.subject_id = pvt.subject_id
  AND tb.hadm_id = pvt.hadm_id
  AND pvt.charttime >= tb.bin_start_time
  AND pvt.charttime < tb.bin_end_time
  AND pvt.label IS NOT NULL

GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
         tb.bin_start_time, tb.bin_end_time, tb.earliestOnset
ORDER BY tb.icustay_id, tb.hour_offset;

-- Add indexes
CREATE INDEX idx_labs_4bin_icustay ON labVals_4bin(icustay_id);
CREATE INDEX idx_labs_4bin_hour ON labVals_4bin(hour_offset);
CREATE INDEX idx_labs_4bin_composite ON labVals_4bin(subject_id, hadm_id, icustay_id, hour_offset);

-- Create imputed lab values table
DROP TABLE IF EXISTS labVals_4bin_imputed;
CREATE TABLE labVals_4bin_imputed AS
WITH lab_stats AS (
  -- Calculate patient-level statistics for each lab
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    AVG(lactate_avg) AS patient_mean_lactate,
    AVG(creatinine_avg) AS patient_mean_creatinine,
    AVG(bilirubin_avg) AS patient_mean_bilirubin,
    AVG(platelet_avg) AS patient_mean_platelet,
    AVG(wbc_avg) AS patient_mean_wbc,
    AVG(glucose_avg) AS patient_mean_glucose,
    AVG(hemoglobin_avg) AS patient_mean_hemoglobin,
    AVG(hematocrit_avg) AS patient_mean_hematocrit,
    AVG(sodium_avg) AS patient_mean_sodium,
    AVG(potassium_avg) AS patient_mean_potassium,
    AVG(chloride_avg) AS patient_mean_chloride,
    AVG(bicarbonate_avg) AS patient_mean_bicarbonate,
    AVG(bun_avg) AS patient_mean_bun,
    AVG(albumin_avg) AS patient_mean_albumin,
    AVG(aniongap_avg) AS patient_mean_aniongap,
    AVG(bands_avg) AS patient_mean_bands,
    AVG(inr_avg) AS patient_mean_inr,
    AVG(pt_avg) AS patient_mean_pt,
    AVG(ptt_avg) AS patient_mean_ptt
  FROM labVals_4bin
  WHERE lactate_avg IS NOT NULL OR creatinine_avg IS NOT NULL 
     OR bilirubin_avg IS NOT NULL OR platelet_avg IS NOT NULL
  GROUP BY subject_id, hadm_id, icustay_id
),
population_stats AS (
  -- Calculate population-level normal ranges (clinical defaults)
  SELECT 
    AVG(lactate_avg) AS pop_mean_lactate,
    AVG(creatinine_avg) AS pop_mean_creatinine,
    AVG(bilirubin_avg) AS pop_mean_bilirubin,
    AVG(platelet_avg) AS pop_mean_platelet,
    AVG(wbc_avg) AS pop_mean_wbc,
    AVG(glucose_avg) AS pop_mean_glucose,
    AVG(hemoglobin_avg) AS pop_mean_hemoglobin,
    AVG(hematocrit_avg) AS pop_mean_hematocrit,
    AVG(sodium_avg) AS pop_mean_sodium,
    AVG(potassium_avg) AS pop_mean_potassium,
    AVG(chloride_avg) AS pop_mean_chloride,
    AVG(bicarbonate_avg) AS pop_mean_bicarbonate,
    AVG(bun_avg) AS pop_mean_bun,
    AVG(albumin_avg) AS pop_mean_albumin,
    AVG(aniongap_avg) AS pop_mean_aniongap,
    AVG(bands_avg) AS pop_mean_bands,
    AVG(inr_avg) AS pop_mean_inr,
    AVG(pt_avg) AS pop_mean_pt,
    AVG(ptt_avg) AS pop_mean_ptt
  FROM labVals_4bin
  WHERE lactate_avg IS NOT NULL OR creatinine_avg IS NOT NULL 
     OR bilirubin_avg IS NOT NULL OR platelet_avg IS NOT NULL
),
forward_filled AS (
  -- Add forward and backward fill for key labs
  SELECT 
    lb.*,
    -- Forward fill key values
    LAG(lactate_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_lactate,
    LAG(creatinine_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_creatinine,
    LAG(bilirubin_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_bilirubin,
    LAG(platelet_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_platelet,
    LAG(wbc_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_wbc,
    LAG(inr_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_inr,
    LAG(pt_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_pt,
    LAG(ptt_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_ptt,
    LAG(bun_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_bun,
    -- Backward fill key values
    LEAD(lactate_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_lactate,
    LEAD(creatinine_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_creatinine,
    LEAD(bilirubin_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_bilirubin,
    LEAD(platelet_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_platelet,
    LEAD(wbc_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_wbc,
    LEAD(inr_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_inr,
    LEAD(pt_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_pt,
    LEAD(ptt_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_ptt,
    LEAD(bun_avg, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_bun
  FROM labVals_4bin lb
)
SELECT 
  ff.subject_id,
  ff.hadm_id,
  ff.icustay_id,
  ff.hour_offset,
  ff.bin_start_time,
  ff.bin_end_time,
  ff.earliestOnset,
  -- Original lab values (keep min/max for clinical interpretation)
  ff.lactate_min,
  ff.lactate_max,
  ff.creatinine_min,
  ff.creatinine_max,
  ff.bilirubin_min,
  ff.bilirubin_max,
  ff.platelet_min,
  ff.platelet_max,
  ff.wbc_min,
  ff.wbc_max,
  ff.inr_min,
  ff.inr_max,
  ff.pt_min,
  ff.pt_max,
  ff.ptt_min,
  ff.ptt_max,
  ff.bun_min,
  ff.bun_max,
  -- Imputed average values for key labs (most important for analysis)
  COALESCE(
    ff.lactate_avg,
    ff.prev_lactate,
    ff.next_lactate,
    ls.patient_mean_lactate,
    ps.pop_mean_lactate,
    1.5                    -- Normal lactate: 0.5-2.2 mmol/L
  ) AS lactate_avg,
  
  COALESCE(
    ff.creatinine_avg,
    ff.prev_creatinine,
    ff.next_creatinine,
    ls.patient_mean_creatinine,
    ps.pop_mean_creatinine,
    1.0                    -- Normal creatinine: 0.6-1.3 mg/dL
  ) AS creatinine_avg,
  
  COALESCE(
    ff.bilirubin_avg,
    ff.prev_bilirubin,
    ff.next_bilirubin,
    ls.patient_mean_bilirubin,
    ps.pop_mean_bilirubin,
    1.0                    -- Normal bilirubin: 0.2-1.2 mg/dL
  ) AS bilirubin_avg,
  
  COALESCE(
    ff.platelet_avg,
    ff.prev_platelet,
    ff.next_platelet,
    ls.patient_mean_platelet,
    ps.pop_mean_platelet,
    250                    -- Normal platelets: 150-400 K/uL
  ) AS platelet_avg,
  
  COALESCE(
    ff.wbc_avg,
    ff.prev_wbc,
    ff.next_wbc,
    ls.patient_mean_wbc,
    ps.pop_mean_wbc,
    8.0                    -- Normal WBC: 4-11 K/uL
  ) AS wbc_avg,
  
  -- Add INR, PT, PTT, BUN with imputation
  COALESCE(
    ff.inr_avg,
    ff.prev_inr,
    ff.next_inr,
    ls.patient_mean_inr,
    ps.pop_mean_inr,
    1.0                    -- Normal INR: 0.8-1.2
  ) AS inr_avg,
  
  COALESCE(
    ff.pt_avg,
    ff.prev_pt,
    ff.next_pt,
    ls.patient_mean_pt,
    ps.pop_mean_pt,
    12.0                   -- Normal PT: 11-15 seconds
  ) AS pt_avg,
  
  COALESCE(
    ff.ptt_avg,
    ff.prev_ptt,
    ff.next_ptt,
    ls.patient_mean_ptt,
    ps.pop_mean_ptt,
    30.0                   -- Normal PTT: 25-35 seconds
  ) AS ptt_avg,
  
  COALESCE(
    ff.bun_avg,
    ff.prev_bun,
    ff.next_bun,
    ls.patient_mean_bun,
    ps.pop_mean_bun,
    15.0                   -- Normal BUN: 7-20 mg/dL
  ) AS bun_avg,

  -- Keep other important labs with basic imputation
  COALESCE(ff.glucose_avg, ls.patient_mean_glucose, ps.pop_mean_glucose, 120) AS glucose_avg,
  COALESCE(ff.hemoglobin_avg, ls.patient_mean_hemoglobin, ps.pop_mean_hemoglobin, 12) AS hemoglobin_avg,
  COALESCE(ff.sodium_avg, ls.patient_mean_sodium, ps.pop_mean_sodium, 140) AS sodium_avg,
  COALESCE(ff.potassium_avg, ls.patient_mean_potassium, ps.pop_mean_potassium, 4.0) AS potassium_avg,
  -- Clinical severity flags
  CASE WHEN COALESCE(ff.lactate_avg, ff.prev_lactate, ff.next_lactate, 
                     ls.patient_mean_lactate, ps.pop_mean_lactate, 1.5) > 4.0 THEN 1 ELSE 0 END AS severe_hyperlactatemia,
  CASE WHEN COALESCE(ff.creatinine_avg, ff.prev_creatinine, ff.next_creatinine, 
                     ls.patient_mean_creatinine, ps.pop_mean_creatinine, 1.0) > 2.0 THEN 1 ELSE 0 END AS acute_kidney_injury,
  CASE WHEN COALESCE(ff.platelet_avg, ff.prev_platelet, ff.next_platelet, 
                     ls.patient_mean_platelet, ps.pop_mean_platelet, 250) < 100 THEN 1 ELSE 0 END AS thrombocytopenia,
  CASE WHEN COALESCE(ff.inr_avg, ff.prev_inr, ff.next_inr, 
                     ls.patient_mean_inr, ps.pop_mean_inr, 1.0) > 1.5 THEN 1 ELSE 0 END AS coagulopathy,
  -- Measurement counts
  ff.lactate_measurements,
  ff.creatinine_measurements,
  ff.bilirubin_measurements,
  ff.platelet_measurements,
  ff.wbc_measurements,
  -- Imputation flags
  CASE WHEN ff.lactate_avg IS NULL THEN 1 ELSE 0 END AS lactate_imputed,
  CASE WHEN ff.creatinine_avg IS NULL THEN 1 ELSE 0 END AS creatinine_imputed,
  CASE WHEN ff.bilirubin_avg IS NULL THEN 1 ELSE 0 END AS bilirubin_imputed,
  CASE WHEN ff.platelet_avg IS NULL THEN 1 ELSE 0 END AS platelet_imputed,
  CASE WHEN ff.wbc_avg IS NULL THEN 1 ELSE 0 END AS wbc_imputed,
  CASE WHEN ff.inr_avg IS NULL THEN 1 ELSE 0 END AS inr_imputed,
  CASE WHEN ff.pt_avg IS NULL THEN 1 ELSE 0 END AS pt_imputed,
  CASE WHEN ff.ptt_avg IS NULL THEN 1 ELSE 0 END AS ptt_imputed,
  CASE WHEN ff.bun_avg IS NULL THEN 1 ELSE 0 END AS bun_imputed

FROM forward_filled ff
LEFT JOIN lab_stats ls
  ON ff.subject_id = ls.subject_id
  AND ff.hadm_id = ls.hadm_id
  AND ff.icustay_id = ls.icustay_id
CROSS JOIN population_stats ps
ORDER BY ff.icustay_id, ff.hour_offset;

-- Add indexes for imputed table
CREATE INDEX idx_labs_imp_icustay ON labVals_4bin_imputed(icustay_id);
CREATE INDEX idx_labs_imp_hour ON labVals_4bin_imputed(hour_offset);
CREATE INDEX idx_labs_imp_lactate ON labVals_4bin_imputed(severe_hyperlactatemia);
CREATE INDEX idx_labs_imp_aki ON labVals_4bin_imputed(acute_kidney_injury);
CREATE INDEX idx_labs_imp_tcp ON labVals_4bin_imputed(thrombocytopenia);
CREATE INDEX idx_labs_imp_coag ON labVals_4bin_imputed(coagulopathy);
-- Verification queries
SELECT * FROM `labVals_4bin_imputed`;