-- Step 1: Create weight tables
DROP TABLE IF EXISTS patient_weights_chart;
CREATE TABLE patient_weights_chart AS
SELECT 
  ie.icustay_id,
  AVG(CASE
    WHEN c.itemid IN (762, 763, 3723, 3580, 226512) THEN c.valuenum
    WHEN c.itemid = 3581 THEN c.valuenum * 0.45359237 -- Convert lbs to kg
    WHEN c.itemid = 3582 THEN c.valuenum * 0.0283495231 -- Convert oz to kg
    ELSE NULL
  END) AS weight
FROM icustays ie
JOIN cohort sc
  ON ie.subject_id = sc.subject_id
  AND ie.hadm_id = sc.hadm_id
  AND ie.icustay_id = sc.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN chartevents c
  ON ie.icustay_id = c.icustay_id
  AND c.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
WHERE c.valuenum IS NOT NULL
  AND c.itemid IN (762, 763, 3723, 3580, 3581, 3582, 226512)
  AND c.valuenum != 0
  AND (c.error IS NULL OR c.error = 0)
GROUP BY ie.icustay_id;

DROP TABLE IF EXISTS patient_weights_echo;
CREATE TABLE patient_weights_echo AS
SELECT 
  ie.icustay_id,
  AVG(echo.weight * 0.45359237) AS weight
FROM icustays ie
JOIN cohort sc
  ON ie.subject_id = sc.subject_id
  AND ie.hadm_id = sc.hadm_id
  AND ie.icustay_id = sc.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN echoData echo
  ON ie.hadm_id = echo.hadm_id
  AND echo.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
GROUP BY ie.icustay_id;

-- Add indexes
CREATE INDEX idx_weights_chart_icustay ON patient_weights_chart(icustay_id);
CREATE INDEX idx_weights_echo_icustay ON patient_weights_echo(icustay_id);

-- Step 2: Create vasopressor tables
DROP TABLE IF EXISTS vasopressors_cv;
CREATE TABLE vasopressors_cv AS
SELECT 
  sc.icustay_id,
  MAX(CASE
    WHEN cv.itemid = 30047 THEN cv.rate / COALESCE(wt.weight, ec.weight) -- mcg/min to mcg/kg/min
    WHEN cv.itemid = 30120 THEN cv.rate -- Assume mcg/kg/min
    ELSE NULL
  END) AS rate_norepinephrine,
  MAX(CASE
    WHEN cv.itemid = 30044 THEN cv.rate / COALESCE(wt.weight, ec.weight) -- mcg/min to mcg/kg/min
    WHEN cv.itemid IN (30119, 30309) THEN cv.rate -- mcg/kg/min
    ELSE NULL
  END) AS rate_epinephrine,
  MAX(CASE WHEN cv.itemid IN (30043, 30307) THEN cv.rate END) AS rate_dopamine,
  MAX(CASE WHEN cv.itemid IN (30042, 30306) THEN cv.rate END) AS rate_dobutamine
FROM cohort sc
JOIN icustays ie
  ON sc.subject_id = ie.subject_id
  AND sc.hadm_id = ie.hadm_id
  AND sc.icustay_id = ie.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN inputevents_cv cv
  ON ie.icustay_id = cv.icustay_id
  AND cv.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
LEFT JOIN patient_weights_chart wt
  ON ie.icustay_id = wt.icustay_id
LEFT JOIN patient_weights_echo ec
  ON ie.icustay_id = ec.icustay_id
WHERE cv.itemid IN (30047, 30120, 30044, 30119, 30309, 30043, 30307, 30042, 30306)
  AND cv.rate IS NOT NULL
GROUP BY sc.icustay_id;

DROP TABLE IF EXISTS vasopressors_mv;
CREATE TABLE vasopressors_mv AS
SELECT 
  sc.icustay_id,
  MAX(CASE WHEN mv.itemid = 221906 THEN mv.rate END) AS rate_norepinephrine,
  MAX(CASE WHEN mv.itemid = 221289 THEN mv.rate END) AS rate_epinephrine,
  MAX(CASE WHEN mv.itemid = 221662 THEN mv.rate END) AS rate_dopamine,
  MAX(CASE WHEN mv.itemid = 221653 THEN mv.rate END) AS rate_dobutamine
FROM cohort sc
JOIN icustays ie
  ON sc.subject_id = ie.subject_id
  AND sc.hadm_id = ie.hadm_id
  AND sc.icustay_id = ie.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN inputevents_mv mv
  ON ie.icustay_id = mv.icustay_id
  AND mv.starttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
WHERE mv.itemid IN (221906, 221289, 221662, 221653)
  AND mv.statusdescription != 'Rewritten'
GROUP BY sc.icustay_id;

-- Add indexes
CREATE INDEX idx_vaso_cv_icustay ON vasopressors_cv(icustay_id);
CREATE INDEX idx_vaso_mv_icustay ON vasopressors_mv(icustay_id);


-- Step 3: Create PaO2/FiO2 ratio tables
DROP TABLE IF EXISTS pafi_intermediate;
CREATE TABLE pafi_intermediate AS
SELECT 
  bg.icustay_id,
  bg.charttime,
  bg.pao2fio2,
  CASE WHEN vd.icustay_id IS NOT NULL THEN 1 ELSE 0 END AS isvent
FROM bloodGasArterial_1 bg
LEFT JOIN ventilation_durations vd
  ON bg.icustay_id = vd.icustay_id
  AND bg.charttime BETWEEN vd.starttime AND vd.endtime;

DROP TABLE IF EXISTS pafi_final;
CREATE TABLE pafi_final AS
SELECT 
  icustay_id,
  MIN(CASE WHEN isvent = 0 THEN pao2fio2 ELSE NULL END) AS pao2fio2_novent_min,
  MIN(CASE WHEN isvent = 1 THEN pao2fio2 ELSE NULL END) AS pao2fio2_vent_min
FROM pafi_intermediate
GROUP BY icustay_id;

-- Add indexes
CREATE INDEX idx_pafi_inter_icustay ON pafi_intermediate(icustay_id);
CREATE INDEX idx_pafi_final_icustay ON pafi_final(icustay_id);


-- Step 4: Combine all SOFA components
DROP TABLE IF EXISTS sofa_components;
CREATE TABLE sofa_components AS
SELECT 
  sc.icustay_id,
  v.meanbp_min,
  COALESCE(cv.rate_norepinephrine, mv.rate_norepinephrine) AS rate_norepinephrine,
  COALESCE(cv.rate_epinephrine, mv.rate_epinephrine) AS rate_epinephrine,
  COALESCE(cv.rate_dopamine, mv.rate_dopamine) AS rate_dopamine,
  COALESCE(cv.rate_dobutamine, mv.rate_dobutamine) AS rate_dobutamine,
  l.creatinine_max,
  l.bilirubin_max,
  l.platelet_min,
  pf.pao2fio2_novent_min,
  pf.pao2fio2_vent_min,
  uo.urineoutput,
  gcs.min_gcs AS mingcs
FROM cohort sc
JOIN icustays ie
  ON sc.subject_id = ie.subject_id
  AND sc.hadm_id = ie.hadm_id
  AND sc.icustay_id = ie.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN vitals_1 v
  ON sc.icustay_id = v.icustay_id
LEFT JOIN labVals_1 l
  ON sc.icustay_id = l.icustay_id
LEFT JOIN urineOutput_1 uo
  ON sc.icustay_id = uo.icustay_id
LEFT JOIN gcs_1 gcs
  ON sc.icustay_id = gcs.icustay_id
LEFT JOIN vasopressors_cv cv
  ON sc.icustay_id = cv.icustay_id
LEFT JOIN vasopressors_mv mv
  ON sc.icustay_id = mv.icustay_id
LEFT JOIN pafi_final pf
  ON sc.icustay_id = pf.icustay_id;

-- Add indexes
CREATE INDEX idx_sofa_comp_icustay ON sofa_components(icustay_id);

-- Step 5: Calculate individual SOFA scores
DROP TABLE IF EXISTS sofa_scores;
CREATE TABLE sofa_scores AS
SELECT 
  icustay_id,
  CASE
    WHEN pao2fio2_vent_min < 100 THEN 4
    WHEN pao2fio2_vent_min < 200 THEN 3
    WHEN pao2fio2_novent_min < 300 THEN 2
    WHEN pao2fio2_novent_min < 400 THEN 1
    WHEN COALESCE(pao2fio2_vent_min, pao2fio2_novent_min) IS NULL THEN NULL
    ELSE 0
  END AS respiration,
  CASE
    WHEN platelet_min < 20 THEN 4
    WHEN platelet_min < 50 THEN 3
    WHEN platelet_min < 100 THEN 2
    WHEN platelet_min < 150 THEN 1
    WHEN platelet_min IS NULL THEN NULL
    ELSE 0
  END AS coagulation,
  CASE
    WHEN bilirubin_max >= 12.0 THEN 4
    WHEN bilirubin_max >= 6.0 THEN 3
    WHEN bilirubin_max >= 2.0 THEN 2
    WHEN bilirubin_max >= 1.2 THEN 1
    WHEN bilirubin_max IS NULL THEN NULL
    ELSE 0
  END AS liver,
  CASE
    WHEN rate_dopamine > 15 OR rate_epinephrine > 0.1 OR rate_norepinephrine > 0.1 THEN 4
    WHEN rate_dopamine > 5 OR rate_epinephrine <= 0.1 OR rate_norepinephrine <= 0.1 THEN 3
    WHEN rate_dopamine > 0 OR rate_dobutamine > 0 THEN 2
    WHEN meanbp_min < 70 THEN 1
    WHEN COALESCE(meanbp_min, rate_dopamine, rate_dobutamine, rate_epinephrine, rate_norepinephrine) IS NULL THEN NULL
    ELSE 0
  END AS cardiovascular,
  CASE
    WHEN mingcs >= 13 AND mingcs <= 14 THEN 1
    WHEN mingcs >= 10 AND mingcs <= 12 THEN 2
    WHEN mingcs >= 6 AND mingcs <= 9 THEN 3
    WHEN mingcs < 6 THEN 4
    WHEN mingcs IS NULL THEN NULL
    ELSE 0
  END AS cns,
  CASE
    WHEN creatinine_max >= 5.0 THEN 4
    WHEN urineoutput < 200 THEN 4
    WHEN creatinine_max >= 3.5 AND creatinine_max < 5.0 THEN 3
    WHEN urineoutput < 500 THEN 3
    WHEN creatinine_max >= 2.0 AND creatinine_max < 3.5 THEN 2
    WHEN creatinine_max >= 1.2 AND creatinine_max < 2.0 THEN 1
    WHEN COALESCE(urineoutput, creatinine_max) IS NULL THEN NULL
    ELSE 0
  END AS renal
FROM sofa_components;

-- Add indexes
CREATE INDEX idx_sofa_scores_icustay ON sofa_scores(icustay_id);
CREATE INDEX idx_sofa_scores_resp ON sofa_scores(respiration);
CREATE INDEX idx_sofa_scores_coag ON sofa_scores(coagulation);


-- Step 6: Create final SOFA table and sepsis cohort
DROP TABLE IF EXISTS sofa_table;
CREATE TABLE sofa_table AS
SELECT 
  ie.subject_id,
  ie.hadm_id,
  ie.icustay_id,
  sc.earliestOnset,
  COALESCE(s.respiration, 0) + COALESCE(s.coagulation, 0) + COALESCE(s.liver, 0) +
  COALESCE(s.cardiovascular, 0) + COALESCE(s.cns, 0) + COALESCE(s.renal, 0) AS SOFA,
  s.respiration,
  s.coagulation,
  s.liver,
  s.cardiovascular,
  s.cns,
  s.renal
FROM cohort sc
JOIN icustays ie
  ON sc.subject_id = ie.subject_id
  AND sc.hadm_id = ie.hadm_id
  AND sc.icustay_id = ie.icustay_id
  AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
LEFT JOIN sofa_scores s
  ON sc.icustay_id = s.icustay_id
ORDER BY ie.icustay_id;

-- Create final sepsis cohort
DROP TABLE IF EXISTS sepsisCohort;
CREATE TABLE sepsisCohort AS
SELECT subject_id, hadm_id, icustay_id, earliestOnset
FROM sofa_table 
WHERE SOFA >= 2;

-- Add final indexes
CREATE INDEX idx_sofa_table_icustay ON sofa_table(icustay_id);

CREATE INDEX idx_sofa_table_subject ON sofa_table(subject_id);
CREATE INDEX idx_sepsis_cohort_subject ON sepsisCohort(subject_id);
CREATE INDEX idx_sepsis_cohort_hadm ON sepsisCohort(hadm_id);
CREATE INDEX idx_sepsis_cohort_icustay ON sepsisCohort(icustay_id);

CREATE INDEX idx_sc_comp ON sepsisCohort(subject_id, hadm_id, icustay_id);

SELECT COUNT(DISTINCT subject_id) FROM `sepsisCohort`;








-- Step 1: Create patient weights from echo data binned into 4-hour intervals
DROP TABLE IF EXISTS patient_weights_echo_4bin;
CREATE TABLE patient_weights_echo_4bin AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  AVG(echo.weight * 0.45359237) AS weight -- Convert lbs to kg
FROM 4hr_time_bins tb
LEFT JOIN echoData echo
  ON tb.hadm_id = echo.hadm_id
  AND echo.charttime >= tb.bin_start_time
  AND echo.charttime < tb.bin_end_time
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
         tb.bin_start_time, tb.bin_end_time;

-- Add indexes
CREATE INDEX idx_weights_echo_4bin_icustay ON patient_weights_echo_4bin(icustay_id);
CREATE INDEX idx_weights_echo_4bin_hour ON patient_weights_echo_4bin(hour_offset);
CREATE INDEX idx_weights_echo_4bin_composite ON patient_weights_echo_4bin(icustay_id, hour_offset);


CREATE INDEX idx_inputevents_cv_icustay_time ON inputevents_cv(icustay_id, charttime);
CREATE INDEX idx_inputevents_cv_itemid ON inputevents_cv(itemid);
CREATE INDEX idx_inputevents_cv_composite ON inputevents_cv(icustay_id, itemid, charttime);

-- Step 2: Create vasopressor tables using 4-hour bins
DROP TABLE IF EXISTS vasopressors_cv_4bin;
CREATE TABLE vasopressors_cv_4bin AS
WITH weight_lookup AS (
  SELECT 
    icustay_id,
    hour_offset,
    COALESCE(di.weight, ec.weight, 80) AS patient_weight
  FROM 4hr_time_bins tb
  LEFT JOIN demographics_imputed di USING (icustay_id, hour_offset)
  LEFT JOIN patient_weights_echo_4bin ec USING (icustay_id, hour_offset)
),
vaso_data AS (
  SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    cv.itemid,
    MAX(cv.rate) AS max_rate,
    wl.patient_weight
  FROM 4hr_time_bins tb
  INNER JOIN inputevents_cv cv
    ON tb.icustay_id = cv.icustay_id
    AND cv.charttime >= tb.bin_start_time
    AND cv.charttime < tb.bin_end_time
    AND cv.itemid IN (30047, 30120, 30044, 30119, 30309, 30043, 30307, 30042, 30306)
    AND cv.rate > 0
  LEFT JOIN weight_lookup wl
    ON tb.icustay_id = wl.icustay_id
    AND tb.hour_offset = wl.hour_offset
  GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset,
           tb.bin_start_time, tb.bin_end_time, cv.itemid, wl.patient_weight
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  MAX(CASE
    WHEN itemid = 30047 THEN max_rate / patient_weight -- mcg/min to mcg/kg/min
    WHEN itemid = 30120 THEN max_rate
    ELSE NULL
  END) AS rate_norepinephrine,
  MAX(CASE
    WHEN itemid = 30044 THEN max_rate / patient_weight
    WHEN itemid IN (30119, 30309) THEN max_rate
    ELSE NULL
  END) AS rate_epinephrine,
  MAX(CASE WHEN itemid IN (30043, 30307) THEN max_rate ELSE NULL END) AS rate_dopamine,
  MAX(CASE WHEN itemid IN (30042, 30306) THEN max_rate ELSE NULL END) AS rate_dobutamine
FROM vaso_data
GROUP BY subject_id, hadm_id, icustay_id, hour_offset, bin_start_time, bin_end_time;

DROP TABLE IF EXISTS vasopressors_mv_4bin;
CREATE TABLE vasopressors_mv_4bin AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  MAX(CASE WHEN mv.itemid = 221906 THEN mv.rate END) AS rate_norepinephrine,
  MAX(CASE WHEN mv.itemid = 221289 THEN mv.rate END) AS rate_epinephrine,
  MAX(CASE WHEN mv.itemid = 221662 THEN mv.rate END) AS rate_dopamine,
  MAX(CASE WHEN mv.itemid = 221653 THEN mv.rate END) AS rate_dobutamine
FROM 4hr_time_bins tb
LEFT JOIN inputevents_mv mv
  ON tb.icustay_id = mv.icustay_id
  AND mv.starttime >= tb.bin_start_time
  AND mv.starttime < tb.bin_end_time
  AND mv.itemid IN (221906, 221289, 221662, 221653)
  AND mv.statusdescription != 'Rewritten'
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset,
         tb.bin_start_time, tb.bin_end_time;

-- Add indexes
CREATE INDEX idx_vaso_cv_4bin_icustay ON vasopressors_cv_4bin(icustay_id);
CREATE INDEX idx_vaso_cv_4bin_hour ON vasopressors_cv_4bin(hour_offset);
CREATE INDEX idx_vaso_mv_4bin_icustay ON vasopressors_mv_4bin(icustay_id);
CREATE INDEX idx_vaso_mv_4bin_hour ON vasopressors_mv_4bin(hour_offset);

-- Step 3: Create PaO2/FiO2 ratio tables using 4-hour bins
DROP TABLE IF EXISTS pafi_intermediate_4bin;
CREATE TABLE pafi_intermediate_4bin AS
SELECT 
  bg.icustay_id,
  bg.bin_start_time,
  bg.bin_end_time,
  bg.hour_offset,
  bg.pao2fio2_avg,
  CASE WHEN vd.icustay_id IS NOT NULL THEN 1 ELSE 0 END AS isvent
FROM bloodGasArterial_4bin_agg_enhanced bg
LEFT JOIN ventilation_4bin vd
  ON bg.icustay_id = vd.icustay_id
  AND bg.bin_start_time = vd.bin_start_time 
  AND vd.bin_end_time = bg.bin_end_time;

DROP TABLE IF EXISTS pafi_final_4bin;
CREATE TABLE pafi_final_4bin AS
SELECT 
  icustay_id,
  hour_offset,
  MIN(CASE WHEN isvent = 0 THEN pao2fio2_avg ELSE NULL END) AS pao2fio2_novent_min,
  MIN(CASE WHEN isvent = 1 THEN pao2fio2_avg ELSE NULL END) AS pao2fio2_vent_min
FROM pafi_intermediate_4bin
GROUP BY icustay_id, hour_offset;

-- Add indexes
CREATE INDEX idx_pafi_inter_icustay ON pafi_intermediate_4bin(icustay_id);
CREATE INDEX idx_pafi_final_icustay ON pafi_final_4bin(icustay_id);  

-- Add indexes
CREATE INDEX idx_pafi_inter_4bin_icustay ON pafi_intermediate_4bin(icustay_id);
CREATE INDEX idx_pafi_inter_4bin_hour ON pafi_intermediate_4bin(hour_offset);
CREATE INDEX idx_pafi_final_4bin_icustay ON pafi_final_4bin(icustay_id);
CREATE INDEX idx_pafi_final_4bin_hour ON pafi_final_4bin(hour_offset);

-- Step 4: Combine all SOFA components using 4-hour bins
DROP TABLE IF EXISTS sofa_components_4bin;
CREATE TABLE sofa_components_4bin AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  v.meanbp_min AS meanbp_min,
  COALESCE(cv.rate_norepinephrine, mv.rate_norepinephrine) AS rate_norepinephrine,
  COALESCE(cv.rate_epinephrine, mv.rate_epinephrine) AS rate_epinephrine,
  COALESCE(cv.rate_dopamine, mv.rate_dopamine) AS rate_dopamine,
  COALESCE(cv.rate_dobutamine, mv.rate_dobutamine) AS rate_dobutamine,
  l.creatinine_max AS creatinine_max,
  l.bilirubin_max AS bilirubin_max,
  l.platelet_min AS platelet_min,
  pf.pao2fio2_novent_min,
  pf.pao2fio2_vent_min,
  uo.urineoutput,
  gcs.avg_gcs_imputed AS mingcs,
  di.weight
FROM 4hr_time_bins tb
LEFT JOIN vitals_4bin_imputed v
  ON tb.icustay_id = v.icustay_id
  AND tb.hour_offset = v.hour_offset
LEFT JOIN labVals_4bin_imputed l
  ON tb.icustay_id = l.icustay_id
  AND tb.hour_offset = l.hour_offset
LEFT JOIN urineOutput_4bin_imputed uo
  ON tb.icustay_id = uo.icustay_id
  AND tb.hour_offset = uo.hour_offset
LEFT JOIN gcs_4bin_imputed gcs
  ON tb.icustay_id = gcs.icustay_id
  AND tb.hour_offset = gcs.hour_offset
LEFT JOIN vasopressors_cv_4bin cv
  ON tb.icustay_id = cv.icustay_id
  AND tb.hour_offset = cv.hour_offset
LEFT JOIN vasopressors_mv_4bin mv
  ON tb.icustay_id = mv.icustay_id
  AND tb.hour_offset = mv.hour_offset
LEFT JOIN pafi_final_4bin pf
  ON tb.icustay_id = pf.icustay_id
  AND tb.hour_offset = pf.hour_offset
LEFT JOIN demographics_imputed di
  ON tb.icustay_id = di.icustay_id
  AND tb.hour_offset = di.hour_offset;

-- Add indexes
CREATE INDEX idx_sofa_comp_4bin_icustay ON sofa_components_4bin(icustay_id);
CREATE INDEX idx_sofa_comp_4bin_hour ON sofa_components_4bin(hour_offset);
CREATE INDEX idx_sofa_comp_4bin_composite ON sofa_components_4bin(icustay_id, hour_offset);

-- Step 5: Calculate individual SOFA scores for each 4-hour bin
DROP TABLE IF EXISTS sofa_scores_4bin;
CREATE TABLE sofa_scores_4bin AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  -- Respiration SOFA
  CASE
    WHEN pao2fio2_vent_min < 100 THEN 4
    WHEN pao2fio2_vent_min < 200 THEN 3
    WHEN pao2fio2_novent_min < 300 THEN 2
    WHEN pao2fio2_novent_min < 400 THEN 1
    WHEN COALESCE(pao2fio2_vent_min, pao2fio2_novent_min) IS NULL THEN 0
    ELSE 0
  END AS respiration,
  -- Coagulation SOFA
  CASE
    WHEN platelet_min < 20 THEN 4
    WHEN platelet_min < 50 THEN 3
    WHEN platelet_min < 100 THEN 2
    WHEN platelet_min < 150 THEN 1
    WHEN platelet_min IS NULL THEN 0
    ELSE 0
  END AS coagulation,
  -- Liver SOFA
  CASE
    WHEN bilirubin_max >= 12.0 THEN 4
    WHEN bilirubin_max >= 6.0 THEN 3
    WHEN bilirubin_max >= 2.0 THEN 2
    WHEN bilirubin_max >= 1.2 THEN 1
    WHEN bilirubin_max IS NULL THEN 0
    ELSE 0
  END AS liver,
  -- Cardiovascular SOFA
  CASE
    WHEN rate_dopamine > 15 OR rate_epinephrine > 0.1 OR rate_norepinephrine > 0.1 THEN 4
    WHEN rate_dopamine > 5 OR rate_epinephrine <= 0.1 OR rate_norepinephrine <= 0.1 THEN 3
    WHEN rate_dopamine > 0 OR rate_dobutamine > 0 THEN 2
    WHEN meanbp_min < 70 THEN 1
    WHEN COALESCE(meanbp_min, rate_dopamine, rate_dobutamine, rate_epinephrine, rate_norepinephrine) IS NULL THEN 0
    ELSE 0
  END AS cardiovascular,
  -- CNS SOFA
  CASE
    WHEN mingcs >= 13 AND mingcs <= 14 THEN 1
    WHEN mingcs >= 10 AND mingcs <= 12 THEN 2
    WHEN mingcs >= 6 AND mingcs <= 9 THEN 3
    WHEN mingcs < 6 THEN 4
    WHEN mingcs IS NULL THEN 0
    ELSE 0
  END AS cns,
  -- Renal SOFA
  CASE
    WHEN creatinine_max >= 5.0 THEN 4
    WHEN urineoutput < 200 THEN 4
    WHEN creatinine_max >= 3.5 AND creatinine_max < 5.0 THEN 3
    WHEN urineoutput < 500 THEN 3
    WHEN creatinine_max >= 2.0 AND creatinine_max < 3.5 THEN 2
    WHEN creatinine_max >= 1.2 AND creatinine_max < 2.0 THEN 1
    WHEN COALESCE(urineoutput, creatinine_max) IS NULL THEN 0
    ELSE 0
  END AS renal,
  -- Component values for reference
  meanbp_min,
  rate_norepinephrine,
  rate_epinephrine,
  rate_dopamine,
  rate_dobutamine,
  creatinine_max,
  bilirubin_max,
  platelet_min,
  pao2fio2_novent_min,
  pao2fio2_vent_min,
  urineoutput,
  mingcs,
  weight
FROM sofa_components_4bin;

select * from sofa_components_4bin;

-- Add indexes
CREATE INDEX idx_sofa_scores_4bin_icustay ON sofa_scores_4bin(icustay_id);
CREATE INDEX idx_sofa_scores_4bin_hour ON sofa_scores_4bin(hour_offset);
CREATE INDEX idx_sofa_scores_4bin_composite ON sofa_scores_4bin(icustay_id, hour_offset);

-- Step 6: Create final SOFA table with total scores for each 4-hour bin
DROP TABLE IF EXISTS sofa_table_4bin;
CREATE TABLE sofa_table_4bin AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  -- Total SOFA score
  COALESCE(respiration, 0) + COALESCE(coagulation, 0) + COALESCE(liver, 0) +
  COALESCE(cardiovascular, 0) + COALESCE(cns, 0) + COALESCE(renal, 0) AS SOFA,
  -- Individual component scores
  respiration,
  coagulation,
  liver,
  cardiovascular,
  cns,
  renal,
  -- Component values for analysis
  meanbp_min,
  rate_norepinephrine,
  rate_epinephrine,
  rate_dopamine,
  rate_dobutamine,
  creatinine_max,
  bilirubin_max,
  platelet_min,
  pao2fio2_novent_min,
  pao2fio2_vent_min,
  urineoutput,
  mingcs,
  weight
FROM sofa_scores_4bin
ORDER BY icustay_id, hour_offset;

-- Add comprehensive indexes
CREATE INDEX idx_sofa_table_4bin_icustay ON sofa_table_4bin(icustay_id);
CREATE INDEX idx_sofa_table_4bin_hour ON sofa_table_4bin(hour_offset);
CREATE INDEX idx_sofa_table_4bin_sofa ON sofa_table_4bin(SOFA);
CREATE INDEX idx_sofa_table_4bin_composite ON sofa_table_4bin(icustay_id, hour_offset);
CREATE INDEX idx_sofa_table_4bin_onset ON sofa_table_4bin(earliestOnset);

SELECT AVG(`SOFA`) from sofa_table_4bin;


DROP TABLE IF EXISTS vasopressors_cv_4bin;
CREATE TABLE vasopressors_cv_4bin AS
SELECT 
    tb.icustay_id,
    tb.hour_offset AS bin,
    MAX(CASE
        WHEN cv.itemid = 30047 THEN cv.rate / COALESCE(wt.weight, ec.weight)
        WHEN cv.itemid = 30120 THEN cv.rate
        ELSE NULL
    END) AS rate_norepinephrine,
    MAX(CASE
        WHEN cv.itemid = 30044 THEN cv.rate / COALESCE(wt.weight, ec.weight)
        WHEN cv.itemid IN (30119, 30309) THEN cv.rate
        ELSE NULL
    END) AS rate_epinephrine,
    MAX(CASE WHEN cv.itemid IN (30043, 30307) THEN cv.rate END) AS rate_dopamine,
    MAX(CASE WHEN cv.itemid IN (30042, 30306) THEN cv.rate END) AS rate_dobutamine
FROM 4hr_time_bins tb
JOIN icustays ie
    ON tb.subject_id = ie.subject_id
    AND tb.hadm_id = ie.hadm_id
    AND tb.icustay_id = ie.icustay_id
LEFT JOIN inputevents_cv cv
    ON tb.icustay_id = cv.icustay_id
    AND cv.charttime >= tb.bin_start_time
    AND cv.charttime < tb.bin_end_time
LEFT JOIN patient_weights_chart wt
    ON tb.icustay_id = wt.icustay_id
LEFT JOIN patient_weights_echo ec
    ON tb.icustay_id = ec.icustay_id
WHERE cv.itemid IN (30047, 30120, 30044, 30119, 30309, 30043, 30307, 30042, 30306)
    AND cv.rate IS NOT NULL
GROUP BY tb.icustay_id, tb.hour_offset;

DROP TABLE IF EXISTS vasopressors_mv_4bin;
CREATE TABLE vasopressors_mv_4bin AS
SELECT 
    tb.icustay_id,
    tb.hour_offset AS bin,
    MAX(CASE WHEN mv.itemid = 221906 THEN mv.rate END) AS rate_norepinephrine,
    MAX(CASE WHEN mv.itemid = 221289 THEN mv.rate END) AS rate_epinephrine,
    MAX(CASE WHEN mv.itemid = 221662 THEN mv.rate END) AS rate_dopamine,
    MAX(CASE WHEN mv.itemid = 221653 THEN mv.rate END) AS rate_dobutamine
FROM 4hr_time_bins tb
JOIN icustays ie
    ON tb.subject_id = ie.subject_id
    AND tb.hadm_id = ie.hadm_id
    AND tb.icustay_id = ie.icustay_id
LEFT JOIN inputevents_mv mv
    ON tb.icustay_id = mv.icustay_id
    AND mv.starttime >= tb.bin_start_time
    AND mv.starttime < tb.bin_end_time
WHERE mv.itemid IN (221906, 221289, 221662, 221653)
    AND mv.statusdescription != 'Rewritten'
GROUP BY tb.icustay_id, tb.hour_offset;

-- Combine vasopressor data
DROP TABLE IF EXISTS vasopressors_4bin;
CREATE TABLE vasopressors_4bin AS
SELECT icustay_id, bin,
       MAX(rate_norepinephrine) AS rate_norepinephrine,
       MAX(rate_epinephrine) AS rate_epinephrine,
       MAX(rate_dopamine) AS rate_dopamine,
       MAX(rate_dobutamine) AS rate_dobutamine
FROM (
    SELECT icustay_id, bin, rate_norepinephrine, rate_epinephrine, rate_dopamine, rate_dobutamine
    FROM vasopressors_cv_4bin
    UNION ALL
    SELECT icustay_id, bin, rate_norepinephrine, rate_epinephrine, rate_dopamine, rate_dobutamine
    FROM vasopressors_mv_4bin
) v
GROUP BY icustay_id, bin;
