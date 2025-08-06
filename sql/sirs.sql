use mimiciii4;

-- SIRS Systemic In ammatory Response Syndrome
-- Step 1: Create blood gas component table
DROP TABLE IF EXISTS sirs_bg_component;
CREATE TABLE sirs_bg_component AS
SELECT 
  bg.icustay_id,
  bg.hour_offset,
  MIN(pco2_imputed) as paco2_min
FROM bloodGasArterial_4bin_agg bg
WHERE (specimen = 'ART' OR specimen_pred = 'ART')
GROUP BY bg.icustay_id, bg.hour_offset;

CREATE INDEX idx_sirs_bg_ids ON sirs_bg_component(icustay_id, hour_offset);

-- Step 2: Create score components table
DROP TABLE IF EXISTS sirs_score_components;
CREATE TABLE sirs_score_components AS
SELECT 
  tb.icustay_id,
  tb.hour_offset,
  v.tempc_min as tempc_min,
  v.tempc_max as tempc_max,
  v.heartrate_max as heartrate_max,
  v.resprate_max as resprate_max,
  bg.paco2_min,
  l.wbc_min as wbc_min,
  l.wbc_max as wbc_max,
  l.bands_max as bands_max
FROM 4hr_time_bins tb
LEFT JOIN sirs_bg_component bg
  ON tb.icustay_id = bg.icustay_id
  AND tb.hour_offset = bg.hour_offset
LEFT JOIN vitals_4bin_imputed v
  ON tb.icustay_id = v.icustay_id
  AND tb.hour_offset = v.hour_offset
LEFT JOIN labVals_4bin l
  ON tb.icustay_id = l.icustay_id
  AND tb.hour_offset = l.hour_offset;

CREATE INDEX idx_sirs_comp_ids ON sirs_score_components(icustay_id, hour_offset);

-- Step 3: Calculate individual scores
DROP TABLE IF EXISTS sirs_score_calc;
CREATE TABLE sirs_score_calc AS
SELECT 
  icustay_id,
  hour_offset,
  
  CASE
    WHEN tempc_min < 36.0 THEN 1
    WHEN tempc_max > 38.0 THEN 1
    WHEN tempc_min IS NULL THEN NULL
    ELSE 0
  END AS temp_score,

  CASE
    WHEN heartrate_max > 90.0 THEN 1
    WHEN heartrate_max IS NULL THEN NULL
    ELSE 0
  END AS heartrate_score,

  CASE
    WHEN resprate_max > 20.0 THEN 1
    WHEN paco2_min < 32.0 THEN 1
    WHEN COALESCE(resprate_max, paco2_min) IS NULL THEN NULL
    ELSE 0
  END AS resp_score,

  CASE
    WHEN wbc_min < 4.0 THEN 1
    WHEN wbc_max > 12.0 THEN 1
    WHEN bands_max > 10 THEN 1 -- > 10% immature neutrophils (band forms)
    WHEN COALESCE(wbc_min, bands_max) IS NULL THEN NULL
    ELSE 0
  END AS wbc_score

FROM sirs_score_components;

CREATE INDEX idx_sirs_calc_ids ON sirs_score_calc(icustay_id, hour_offset);

-- Step 4: Final SIRS table
DROP TABLE IF EXISTS sirs_4bin;
CREATE TABLE sirs_4bin AS
SELECT
  tb.subject_id, 
  tb.hadm_id, 
  tb.icustay_id, 
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  -- Combine all the scores to get SIRS
  -- Impute 0 if the score is missing
  COALESCE(s.temp_score, 0) +
  COALESCE(s.heartrate_score, 0) +
  COALESCE(s.resp_score, 0) +
  COALESCE(s.wbc_score, 0) AS sirs,
  
  s.temp_score, 
  s.heartrate_score, 
  s.resp_score, 
  s.wbc_score
  
FROM 4hr_time_bins tb
LEFT JOIN sirs_score_calc s
  ON tb.icustay_id = s.icustay_id
  AND tb.hour_offset = s.hour_offset
ORDER BY tb.icustay_id, tb.hour_offset;

-- Add final indexes
CREATE INDEX idx_sirs_4bin_icustay ON sirs_4bin(icustay_id);
CREATE INDEX idx_sirs_4bin_hour ON sirs_4bin(hour_offset);
CREATE INDEX idx_sirs_4bin_sirs ON sirs_4bin(sirs);
CREATE INDEX idx_sirs_4bin_composite ON sirs_4bin(subject_id, hadm_id, icustay_id, hour_offset);

-- Cleanup intermediate tables (optional)
-- DROP TABLE sirs_bg_component;
-- DROP TABLE sirs_score_components;
-- DROP TABLE sirs_score_calc;

-- View final results
SELECT AVG(sirs) FROM sirs_4bin;

