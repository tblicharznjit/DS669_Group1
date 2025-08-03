
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