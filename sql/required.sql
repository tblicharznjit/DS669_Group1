USE mimiciii4;

DROP TABLE IF EXISTS cohort;

CREATE TABLE all_events AS 
SELECT icustay_id, charttime AS event_time
FROM chartevents -- rows=263,201,375
WHERE icustay_id IS NOT NULL

UNION

SELECT icustay_id, charttime AS event_time
FROM outputevents -- rows=4,349,339
WHERE icustay_id IS NOT NULL

UNION

SELECT icustay_id, charttime AS event_time
FROM inputevents_cv -- rows=17,528,894
WHERE icustay_id IS NOT NULL

UNION

SELECT icustay_id, starttime AS event_time
FROM inputevents_mv -- rows=3,618,991
WHERE icustay_id IS NOT NULL

UNION

SELECT i.icustay_id, l.charttime AS event_time
FROM labevents l -- rows=27,872,575
JOIN icustays i
ON l.subject_id = i.subject_id
AND l.hadm_id = i.hadm_id
WHERE l.charttime BETWEEN i.intime AND i.outtime;

CREATE INDEX idx_all_events_icustay ON all_events(icustay_id);
CREATE INDEX idx_all_events_time ON all_events(event_time);

DROP TABLE IF EXISTS event_time;
CREATE TABLE event_times AS
SELECT
i.icustay_id,
i.intime,
i.outtime,
e.event_time,
LAG(e.event_time) OVER (PARTITION BY i.icustay_id ORDER BY e.event_time) AS prev_event_time
FROM icustays i
LEFT JOIN all_events e
ON i.icustay_id = e.icustay_id

CREATE INDEX idx_event_times_icustay ON event_times(icustay_id);

CREATE TABLE gaps AS
SELECT
icustay_id,
intime,
outtime,
event_time,
prev_event_time,

CASE
    WHEN  MIN(event_time) OVER (PARTITION BY icustay_id) IS NULL THEN TIMESTAMPDIFF(SECOND, intime, outtime)
    ELSE TIMESTAMPDIFF(SECOND, intime, MIN(event_time) OVER (PARTITION BY icustay_id))
END AS start_gap,

CASE
    WHEN prev_event_time IS NULL THEN 0
    ELSE TIMESTAMPDIFF(SECOND, prev_event_time, event_time)
END AS internal_gap,

CASE
    WHEN MAX(event_time) OVER (PARTITION BY icustay_id) IS NULL THEN TIMESTAMPDIFF(SECOND, intime, outtime)
    ELSE TIMESTAMPDIFF(SECOND, MAX(event_time) OVER (PARTITION BY icustay_id), outtime)
END AS end_gap
FROM event_times;


CREATE TABLE icu_stays_with_gaps AS
SELECT DISTINCT icustay_id
FROM gaps
WHERE start_gap > 86400
OR internal_gap > 86400
OR end_gap > 86400;

CREATE TABLE patients_to_exclude AS 
SELECT DISTINCT i.subject_id
FROM icustays i
JOIN icu_stays_with_gaps g
ON i.icustay_id = g.icustay_id;

CREATE TABLE adults AS 
SELECT
a.ROW_ID AS ADMISSION_ROW_ID,
a.SUBJECT_ID,
a.HADM_ID,
a.ADMITTIME,
a.DISCHTIME,
a.DEATHTIME,
a.ADMISSION_TYPE,
a.ETHNICITY,
a.EDREGTIME,
a.EDOUTTIME,
a.HOSPITAL_EXPIRE_FLAG,
p.ROW_ID AS PATIENT_ROW_ID,
p.GENDER,
p.DOB,
p.DOD,
p.DOD_HOSP,
p.EXPIRE_FLAG,
ROUND(
TIMESTAMPDIFF(SECOND, p.DOB, a.ADMITTIME) / (365.25*24*60*60),
2
) AS AGE
FROM `ADMISSIONS` a
JOIN `PATIENTS` p ON a.SUBJECT_ID = p.SUBJECT_ID
WHERE TIMESTAMPDIFF(SECOND, p.DOB, a.ADMITTIME) / (365.25*24*60*60) >= 18
AND a.DISCHARGE_LOCATION != 'HOSPICE - MEDICAL FACILITY';
CREATE INDEX idx_adults_subject ON adults(SUBJECT_ID);
CREATE INDEX idx_adults_hadm ON adults(HADM_ID);

CREATE TABLE adultsTreated AS 
SELECT * FROM adults a
WHERE NOT EXISTS(
SELECT 1
FROM `NOTEEVENTS` ne -- rows=2,078,705
WHERE ne.`SUBJECT_ID` = a.`SUBJECT_ID` 
AND ne.`HADM_ID` = a.`HADM_ID`
AND (
LOWER(ne.TEXT) LIKE '%withdraw treatment%'
OR LOWER(ne.TEXT) LIKE '%comfort care%'
OR LOWER(ne.TEXT) LIKE '%comfort measures only%'
OR LOWER(ne.TEXT) LIKE '%care withdrawn at%'
OR LOWER(ne.TEXT) LIKE '%care withdrawn @%'
OR LOWER(ne.TEXT) LIKE '%transitioned to comfort%'
OR LOWER(ne.TEXT) LIKE '%withdraw life support%'
OR LOWER(ne.TEXT) LIKE '%terminal extubation%'
OR LOWER(ne.TEXT) LIKE '%extubated for comfort%'
OR LOWER(ne.TEXT) LIKE '%terminal wean%'
OR LOWER(ne.TEXT) LIKE '%aggressive measures stopped%' 
OR LOWER(ne.TEXT) LIKE '%family agreed to comfort%' 
OR LOWER(ne.TEXT) LIKE '%de-escalation of care%'
OR LOWER(ne.TEXT) LIKE '%palliative care only%'
OR LOWER(ne.TEXT) LIKE '%ventilator removed for comfort%'
OR LOWER(ne.TEXT) LIKE '%goal of care changed to comfort%'
OR LOWER(ne.TEXT) LIKE '%no escalation of care%'
OR LOWER(ne.TEXT) LIKE '%code status changed%'
OR LOWER(ne.TEXT) LIKE '%transitioned to palliative care%'
OR LOWER(ne.TEXT) LIKE '%withdraw ventilator support%'
OR LOWER(ne.TEXT) LIKE '%extubated for comfort only%'
OR LOWER(ne.TEXT) LIKE '%de-escalated care plan%'
OR LOWER(ne.TEXT) LIKE '%comfort-focused care%'
OR LOWER(ne.TEXT) LIKE '%focus on comfort%')
);

CREATE INDEX idx_adultsTreated_subject ON adultsTreated(SUBJECT_ID);
CREATE INDEX idx_adultsTreated_hadm ON adultsTreated(HADM_ID);

CREATE TABLE antibiotic_items AS 
SELECT d.itemid, d.label
FROM d_items d
WHERE lower(d.category) like '%antibiotic%'
OR LOWER(d.label) like '%adoxa%' 
OR lower(d.label) like '%ala-tet%' 
OR lower(d.label) like '%alodox%' 
OR lower(d.label) like '%amikacin%' 
OR lower(d.label) like '%amikin%' 
OR lower(d.label) like '%amoxicillin%' 
OR lower(d.label) like '%amoxicillin%clavulanate%' 
OR lower(d.label) like '%clavulanate%' 
OR lower(d.label) like '%ampicillin%' 
OR lower(d.label) like '%augmentin%' 
OR lower(d.label) like '%avelox%' 
OR lower(d.label) like '%avidoxy%' 
OR lower(d.label) like '%azactam%' 
OR lower(d.label) like '%azithromycin%' 
OR lower(d.label) like '%aztreonam%' 
OR lower(d.label) like '%axetil%' 
OR lower(d.label) like '%bactocill%' 
OR lower(d.label) like '%bactrim%' 
OR lower(d.label) like '%bethkis%' 
OR lower(d.label) like '%biaxin%' 
OR lower(d.label) like '%bicillin l-a%' 
OR lower(d.label) like '%cayston%' 
OR lower(d.label) like '%cefazolin%' 
OR lower(d.label) like '%cedax%' 
OR lower(d.label) like '%cefoxitin%' 
OR lower(d.label) like '%ceftazidime%' 
OR lower(d.label) like '%cefaclor%' 
OR lower(d.label) like '%cefadroxil%' 
OR lower(d.label) like '%cefdinir%' 
OR lower(d.label) like '%cefditoren%' 
OR lower(d.label) like '%cefepime%' 
OR lower(d.label) like '%cefotetan%' 
OR lower(d.label) like '%cefotaxime%' 
OR lower(d.label) like '%cefpodoxime%' 
OR lower(d.label) like '%cefprozil%' 
OR lower(d.label) like '%ceftibuten%' 
OR lower(d.label) like '%ceftin%' 
OR lower(d.label) like '%cefuroxime %' 
OR lower(d.label) like '%cefuroxime%' 
OR lower(d.label) like '%cephalexin%' 
OR lower(d.label) like '%chloramphenicol%' 
OR lower(d.label) like '%cipro%' 
OR lower(d.label) like '%ciprofloxacin%' 
OR lower(d.label) like '%claforan%' 
OR lower(d.label) like '%clarithromycin%' 
OR lower(d.label) like '%cleocin%' 
OR lower(d.label) like '%clindamycin%' 
OR lower(d.label) like '%cubicin%' 
OR lower(d.label) like '%dicloxacillin%' 
OR lower(d.label) like '%doryx%' 
OR lower(d.label) like '%doxycycline%' 
OR lower(d.label) like '%duricef%' 
OR lower(d.label) like '%dynacin%' 
OR lower(d.label) like '%ery-tab%' 
OR lower(d.label) like '%eryped%' 
OR lower(d.label) like '%eryc%' 
OR lower(d.label) like '%erythrocin%' 
OR lower(d.label) like '%erythromycin%' 
OR lower(d.label) like '%factive%' 
OR lower(d.label) like '%flagyl%' 
OR lower(d.label) like '%fortaz%' 
OR lower(d.label) like '%furadantin%' 
OR lower(d.label) like '%garamycin%' 
OR lower(d.label) like '%gentamicin%' 
OR lower(d.label) like '%kanamycin%' 
OR lower(d.label) like '%keflex%' 
OR lower(d.label) like '%ketek%' 
OR lower(d.label) like '%levaquin%' 
OR lower(d.label) like '%levofloxacin%' 
OR lower(d.label) like '%lincocin%' 
OR lower(d.label) like '%macrobid%' 
OR lower(d.label) like '%macrodantin%' 
OR lower(d.label) like '%maxipime%' 
OR lower(d.label) like '%mefoxin%' 
OR lower(d.label) like '%metronidazole%' 
OR lower(d.label) like '%minocin%' 
OR lower(d.label) like '%minocycline%' 
OR lower(d.label) like '%monodox%' 
OR lower(d.label) like '%monurol%' 
OR lower(d.label) like '%morgidox%' 
OR lower(d.label) like '%moxatag%' 
OR lower(d.label) like '%moxifloxacin%' 
OR lower(d.label) like '%myrac%' 
OR lower(d.label) like '%nafcillin sodium%' 
OR lower(d.label) like '%nicazel doxy 30%' 
OR lower(d.label) like '%nitrofurantoin%' 
OR lower(d.label) like '%noroxin%' 
OR lower(d.label) like '%ocudox%' 
OR lower(d.label) like '%ofloxacin%' 
OR lower(d.label) like '%omnicef%' 
OR lower(d.label) like '%oracea%' 
OR lower(d.label) like '%oraxyl%' 
OR lower(d.label) like '%oxacillin%' 
OR lower(d.label) like '%pc pen vk%' 
OR lower(d.label) like '%pce dispertab%' 
OR lower(d.label) like '%panixine%' 
OR lower(d.label) like '%pediazole%' 
OR lower(d.label) like '%penicillin%' 
OR lower(d.label) like '%periostat%' 
OR lower(d.label) like '%pfizerpen%' 
OR lower(d.label) like '%piperacillin%' 
OR lower(d.label) like '%tazobactam%' 
OR lower(d.label) like '%primsol%' 
OR lower(d.label) like '%proquin%' 
OR lower(d.label) like '%raniclor%' 
OR lower(d.label) like '%rifadin%' 
OR lower(d.label) like '%rifampin%' 
OR lower(d.label) like '%rocephin%' 
OR lower(d.label) like '%smz-tmp%' 
OR lower(d.label) like '%septra%' 
OR lower(d.label) like '%septra ds%' 
OR lower(d.label) like '%septra%' 
OR lower(d.label) like '%solodyn%' 
OR lower(d.label) like '%spectracef%' 
OR lower(d.label) like '%streptomycin sulfate%' 
OR lower(d.label) like '%sulfadiazine%' 
OR lower(d.label) like '%sulfamethoxazole%' 
OR lower(d.label) like '%trimethoprim%' 
OR lower(d.label) like '%sulfatrim%' 
OR lower(d.label) like '%sulfisoxazole%' 
OR lower(d.label) like '%suprax%' 
OR lower(d.label) like '%synercid%' 
OR lower(d.label) like '%tazicef%' 
OR lower(d.label) like '%tetracycline%' 
OR lower(d.label) like '%timentin%' 
OR lower(d.label) like '%tobi%' 
OR lower(d.label) like '%tobramycin%' 
OR lower(d.label) like '%trimethoprim%' 
OR lower(d.label) like '%unasyn%' 
OR lower(d.label) like '%vancocin%' 
OR lower(d.label) like '%vancomycin%' 
OR lower(d.label) like '%vantin%' 
OR lower(d.label) like '%vibativ%' 
OR lower(d.label) like '%vibra-tabs%' 
OR lower(d.label) like '%vibramycin%' 
OR lower(d.label) like '%zinacef%' 
OR lower(d.label) like '%zithromax%' 
OR lower(d.label) like '%zmax%' 
OR lower(d.label) like '%zosyn%' 
OR lower(d.label) like '%zyvox%';

CREATE TABLE  all_antibiotics  AS 
SELECT p.subject_id, p.hadm_id, i.icustay_id, p.startdate as admin_time, p.drug AS drug_name, 'Prescription' AS source
FROM prescriptions p JOIN icustays i
ON p.subject_id = i.subject_id
AND p.hadm_id = i.hadm_id
AND p.startdate BETWEEN i.intime AND i.outtime
WHERE lower(drug) like '%adoxa%' 
OR lower(drug) like '%ala-tet%' 
OR lower(drug) like '%alodox%' 
OR lower(drug) like '%amikacin%' 
OR lower(drug) like '%amikin%' 
OR lower(drug) like '%amoxicillin%' 
OR lower(drug) like '%amoxicillin%clavulanate%' 
OR lower(drug) like '%clavulanate%' 
OR lower(drug) like '%ampicillin%' 
OR lower(drug) like '%augmentin%' 
OR lower(drug) like '%avelox%' 
OR lower(drug) like '%avidoxy%' 
OR lower(drug) like '%azactam%' 
OR lower(drug) like '%azithromycin%' 
OR lower(drug) like '%aztreonam%' 
OR lower(drug) like '%axetil%' 
OR lower(drug) like '%bactocill%' 
OR lower(drug) like '%bactrim%' 
OR lower(drug) like '%bethkis%' 
OR lower(drug) like '%biaxin%' 
OR lower(drug) like '%bicillin l-a%' 
OR lower(drug) like '%cayston%' 
OR lower(drug) like '%cefazolin%' 
OR lower(drug) like '%cedax%' 
OR lower(drug) like '%cefoxitin%' 
OR lower(drug) like '%ceftazidime%' 
OR lower(drug) like '%cefaclor%' 
OR lower(drug) like '%cefadroxil%' 
OR lower(drug) like '%cefdinir%' 
OR lower(drug) like '%cefditoren%' 
OR lower(drug) like '%cefepime%' 
OR lower(drug) like '%cefotetan%' 
OR lower(drug) like '%cefotaxime%' 
OR lower(drug) like '%cefpodoxime%' 
OR lower(drug) like '%cefprozil%' 
OR lower(drug) like '%ceftibuten%' 
OR lower(drug) like '%ceftin%' 
OR lower(drug) like '%cefuroxime %' 
OR lower(drug) like '%cefuroxime%' 
OR lower(drug) like '%cephalexin%' 
OR lower(drug) like '%chloramphenicol%' 
OR lower(drug) like '%cipro%' 
OR lower(drug) like '%ciprofloxacin%' 
OR lower(drug) like '%claforan%' 
OR lower(drug) like '%clarithromycin%' 
OR lower(drug) like '%cleocin%' 
OR lower(drug) like '%clindamycin%' 
OR lower(drug) like '%cubicin%' 
OR lower(drug) like '%dicloxacillin%' 
OR lower(drug) like '%doryx%' 
OR lower(drug) like '%doxycycline%' 
OR lower(drug) like '%duricef%' 
OR lower(drug) like '%dynacin%' 
OR lower(drug) like '%ery-tab%' 
OR lower(drug) like '%eryped%' 
OR lower(drug) like '%eryc%' 
OR lower(drug) like '%erythrocin%' 
OR lower(drug) like '%erythromycin%' 
OR lower(drug) like '%factive%' 
OR lower(drug) like '%flagyl%' 
OR lower(drug) like '%fortaz%' 
OR lower(drug) like '%furadantin%' 
OR lower(drug) like '%garamycin%' 
OR lower(drug) like '%gentamicin%' 
OR lower(drug) like '%kanamycin%' 
OR lower(drug) like '%keflex%' 
OR lower(drug) like '%ketek%' 
OR lower(drug) like '%levaquin%' 
OR lower(drug) like '%levofloxacin%' 
OR lower(drug) like '%lincocin%' 
OR lower(drug) like '%macrobid%' 
OR lower(drug) like '%macrodantin%' 
OR lower(drug) like '%maxipime%' 
OR lower(drug) like '%mefoxin%' 
OR lower(drug) like '%metronidazole%' 
OR lower(drug) like '%minocin%' 
OR lower(drug) like '%minocycline%' 
OR lower(drug) like '%monodox%' 
OR lower(drug) like '%monurol%' 
OR lower(drug) like '%morgidox%' 
OR lower(drug) like '%moxatag%' 
OR lower(drug) like '%moxifloxacin%' 
OR lower(drug) like '%myrac%' 
OR lower(drug) like '%nafcillin sodium%' 
OR lower(drug) like '%nicazel doxy 30%' 
OR lower(drug) like '%nitrofurantoin%' 
OR lower(drug) like '%noroxin%' 
OR lower(drug) like '%ocudox%' 
OR lower(drug) like '%ofloxacin%' 
OR lower(drug) like '%omnicef%' 
OR lower(drug) like '%oracea%' 
OR lower(drug) like '%oraxyl%' 
OR lower(drug) like '%oxacillin%' 
OR lower(drug) like '%pc pen vk%' 
OR lower(drug) like '%pce dispertab%' 
OR lower(drug) like '%panixine%' 
OR lower(drug) like '%pediazole%' 
OR lower(drug) like '%penicillin%' 
OR lower(drug) like '%periostat%' 
OR lower(drug) like '%pfizerpen%' 
OR lower(drug) like '%piperacillin%' 
OR lower(drug) like '%tazobactam%' 
OR lower(drug) like '%primsol%' 
OR lower(drug) like '%proquin%' 
OR lower(drug) like '%raniclor%' 
OR lower(drug) like '%rifadin%' 
OR lower(drug) like '%rifampin%' 
OR lower(drug) like '%rocephin%' 
OR lower(drug) like '%smz-tmp%' 
OR lower(drug) like '%septra%' 
OR lower(drug) like '%septra ds%' 
OR lower(drug) like '%septra%' 
OR lower(drug) like '%solodyn%' 
OR lower(drug) like '%spectracef%' 
OR lower(drug) like '%streptomycin sulfate%' 
OR lower(drug) like '%sulfadiazine%' 
OR lower(drug) like '%sulfamethoxazole%' 
OR lower(drug) like '%trimethoprim%' 
OR lower(drug) like '%sulfatrim%' 
OR lower(drug) like '%sulfisoxazole%' 
OR lower(drug) like '%suprax%' 
OR lower(drug) like '%synercid%' 
OR lower(drug) like '%tazicef%' 
OR lower(drug) like '%tetracycline%' 
OR lower(drug) like '%timentin%' 
OR lower(drug) like '%tobi%' 
OR lower(drug) like '%tobramycin%' 
OR lower(drug) like '%trimethoprim%' 
OR lower(drug) like '%unasyn%' 
OR lower(drug) like '%vancocin%' 
OR lower(drug) like '%vancomycin%' 
OR lower(drug) like '%vantin%' 
OR lower(drug) like '%vibativ%' 
OR lower(drug) like '%vibra-tabs%' 
OR lower(drug) like '%vibramycin%' 
OR lower(drug) like '%zinacef%' 
OR lower(drug) like '%zithromax%' 
OR lower(drug) like '%zmax%' 
OR lower(drug) like '%zosyn%' 
OR lower(drug) like '%zyvox%'
UNION 
SELECT 
ie.subject_id,
ie.hadm_id,
ie.icustay_id,
ie.charttime AS admin_time,
d.label AS drug_name,
'Input_CareVue' AS source
FROM inputevents_cv ie
JOIN antibiotic_items d
ON ie.itemid = d.itemid
WHERE ie.icustay_id IS NOT NULL
UNION
SELECT 
ie.subject_id,
ie.hadm_id,
ie.icustay_id,
ie.starttime AS admin_time,
d.label AS drug_name,
'Input_MetaVision' AS source
FROM inputevents_mv ie
JOIN antibiotic_items d
ON ie.itemid = d.itemid
WHERE ie.icustay_id IS NOT NULL;

CREATE INDEX idx_all_antibiotics_subject ON all_antibiotics(subject_id);
CREATE INDEX idx_all_antibiotics_hadm ON all_antibiotics(hadm_id);
CREATE INDEX idx_all_antibiotics_icustay ON all_antibiotics(icustay_id);

CREATE TABLE microbiology_icu AS 
SELECT 
m.subject_id,
m.hadm_id,
m.charttime AS micro_time,
i.icustay_id
FROM microbiologyevents m
JOIN icustays i
ON m.subject_id = i.subject_id
AND m.hadm_id = i.hadm_id
AND m.charttime BETWEEN i.intime AND i.outtime;

CREATE TABLE pairs AS 
SELECT 
m.subject_id,
m.hadm_id,
m.icustay_id,
m.micro_time,
a.admin_time,
LEAST(m.micro_time, a.admin_time) AS onset_time
FROM microbiology_icu m
JOIN all_antibiotics a
ON m.subject_id = a.subject_id 
AND m.hadm_id = a.hadm_id
AND m.icustay_id = a.icustay_id
WHERE 
(m.micro_time < a.admin_time AND TIMESTAMPDIFF(HOUR, m.micro_time, a.admin_time) <= 72)
OR
(a.admin_time < m.micro_time AND TIMESTAMPDIFF(HOUR, a.admin_time, m.micro_time) <= 24);

DROP TABLE IF EXISTS cohort;
CREATE TABLE cohort AS
SELECT 
    a.SUBJECT_ID,
    a.HADM_ID,
    i.ICUSTAY_ID,
    a.AGE,
    MIN(p.onset_time) AS earliestOnset
FROM adultsTreated a
JOIN pairs p ON 
p.subject_id = a.subject_id AND p.hadm_id = a.hadm_id
JOIN icustays i ON
a.subject_id = i.subject_id AND a.hadm_id = i.hadm_id
WHERE a.subject_id NOT IN (SELECT subject_id FROM patients_to_exclude)
GROUP BY a.SUBJECT_ID, a.HADM_ID, i.ICUSTAY_ID, a.AGE;


SELECT COUNT(DISTINCT subject_id) FROM cohort;


-- First, necessary indexes
CREATE INDEX idx_chartevents_icustay_time ON chartevents(icustay_id, charttime);
CREATE INDEX idx_chartevents_itemid ON chartevents(itemid);
CREATE INDEX idx_cohort_composite ON cohort(subject_id, hadm_id, icustay_id);



-- Step 0: Create 4-hour time bins for each patient
DROP TABLE IF EXISTS 4hr_time_bins;
CREATE TABLE 4hr_time_bins AS
WITH RECURSIVE time_sequence AS (
    -- Start from -24 hours, go to +56 hours in 4-hour increments
    SELECT -24 AS hour_offset
    UNION ALL
    SELECT hour_offset + 4
    FROM time_sequence
    WHERE hour_offset < 56
)
SELECT 
    c.subject_id,
    c.hadm_id,
    c.icustay_id,
    c.earliestOnset,
    ts.hour_offset,
    DATE_ADD(c.earliestOnset, INTERVAL ts.hour_offset HOUR) AS bin_start_time,
    DATE_ADD(c.earliestOnset, INTERVAL (ts.hour_offset + 4) HOUR) AS bin_end_time
FROM sepsisCohort c
CROSS JOIN time_sequence ts
ORDER BY c.icustay_id, ts.hour_offset;

SELECT * FROM 4hr_time_bins;

CREATE INDEX idx_time_bins_icustay ON 4hr_time_bins(icustay_id);
CREATE INDEX idx_time_bins_times ON 4hr_time_bins(bin_start_time, bin_end_time);

CREATE INDEX idx_chartevents_composite ON chartevents(icustay_id, itemid, charttime, valuenum);
CREATE INDEX idx_chartevents_composite1 ON chartevents(icustay_id, hadm_id, subject_id);
CREATE INDEX idx_time_bins_composite ON 4hr_time_bins(icustay_id, hour_offset, bin_start_time, bin_end_time);

CREATE TABLE ceFiltered AS
SELECT 
sc.subject_id,
sc.hadm_id, 
sc.icustay_id,
sc.earliestOnset,
ce.row_id,
ce.charttime,
ce.storetime,
ce.itemid,
ce.value,
ce.valuenum,
ce.valueuom,
ce.warning,
ce.error,
ce.resultstatus,
ce.stopped
FROM sepsisCohort sc 
JOIN chartevents ce 
ON sc.subject_id = ce.subject_id 
AND sc.hadm_id = ce.hadm_id 
AND sc.icustay_id = ce.icustay_id;

-- Primary identification indexes
CREATE INDEX idx_ceFiltered_subject ON ceFiltered(subject_id);
CREATE INDEX idx_ceFiltered_hadm ON ceFiltered(hadm_id);
CREATE INDEX idx_ceFiltered_icustay ON ceFiltered(icustay_id);

-- Time-based indexes (critical for time binning)
CREATE INDEX idx_ceFiltered_charttime ON ceFiltered(charttime);
CREATE INDEX idx_ceFiltered_icustay_time ON ceFiltered(icustay_id, charttime);

-- Item-based indexes (for filtering measurements)
CREATE INDEX idx_ceFiltered_itemid ON ceFiltered(itemid);
CREATE INDEX idx_ceFiltered_itemid_time ON ceFiltered(itemid, charttime);

-- Value-based indexes (for filtering valid data)
CREATE INDEX idx_ceFiltered_valuenum ON ceFiltered(valuenum);
CREATE INDEX idx_ceFiltered_error ON ceFiltered(error);

-- Ultimate performance index for time binning queries
CREATE INDEX idx_ceFiltered_ultimate ON ceFiltered(icustay_id, itemid, charttime, valuenum);

-- Time range filtering
CREATE INDEX idx_ceFiltered_icustay_item_time ON ceFiltered(icustay_id, itemid, charttime);

-- Data quality filtering
CREATE INDEX idx_ceFiltered_quality ON ceFiltered(icustay_id, itemid, valuenum, error);

-- Onset-based filtering 
CREATE INDEX idx_ceFiltered_onset_filter ON ceFiltered(subject_id, hadm_id, icustay_id, charttime);



-- weight
CREATE TABLE weight_4bin AS
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    AVG(CASE
        WHEN c.itemid IN (762, 763, 3723, 3580, 226512) THEN c.valuenum
        WHEN c.itemid = 3581 THEN c.valuenum * 0.45359237
        WHEN c.itemid = 3582 THEN c.valuenum * 0.0283495231
        ELSE NULL
    END) AS weight
FROM 4hr_time_bins tb
LEFT JOIN ceFiltered c
    ON tb.icustay_id = c.icustay_id
    AND c.charttime >= tb.bin_start_time
    AND c.charttime < tb.bin_end_time
    AND c.itemid IN (762, 763, 3723, 3580, 3581, 3582, 226512)
    AND c.valuenum IS NOT NULL 
    AND c.valuenum != 0
    AND (c.error IS NULL OR c.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset;

CREATE INDEX idx_weight_bins_icustay ON weight_4bin(icustay_id);
CREATE INDEX idx_weight_bins_sub ON weight_4bin(subject_id);
CREATE INDEX idx_weight_bins_hadm ON weight_4bin(hadm_id);
CREATE INDEX idx_weight_bins_composite ON weight_4bin(subject_id, hadm_id,icustay_id);

SELECT * FROM weight_4bin;

-- Step 2: final demographics table
DROP TABLE IF EXISTS demographics;
CREATE TABLE demographics AS
SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    a.AGE AS age,
    CASE WHEN a.gender = 'M' THEN 1 ELSE 0 END AS gender,
    CASE WHEN a.ethnicity LIKE '%WHITE%' THEN 1 ELSE 0 END AS race_white,
    CASE WHEN a.ethnicity LIKE '%BLACK%' THEN 1 ELSE 0 END AS race_black,
    CASE WHEN a.ethnicity LIKE '%ASIAN%' THEN 1 ELSE 0 END AS race_asian,
    CASE WHEN a.ethnicity LIKE '%HISPANIC%' OR a.ethnicity LIKE '%LATINO%' THEN 1 ELSE 0 END AS race_latino,
    CASE 
        WHEN a.ethnicity NOT LIKE '%WHITE%' AND a.ethnicity NOT LIKE '%BLACK%' 
        AND a.ethnicity NOT LIKE '%ASIAN%' AND a.ethnicity NOT LIKE '%HISPANIC%' 
        AND a.ethnicity NOT LIKE '%LATINO%' THEN 1 ELSE 0 
    END AS race_other,
    CASE 
        WHEN a.deathtime IS NOT NULL 
        AND a.deathtime <= DATE_ADD(sc.earliestOnset, INTERVAL 90 DAY) 
        THEN 1 -- died within 90 days of onset.
        ELSE 0 
    END AS mortality_90day,
    a.expire_flag as death,
    hour_offset,
    w.weight
FROM sepsisCohort sc
JOIN adultsTreated a
    ON sc.subject_id = a.subject_id
    AND sc.hadm_id = a.hadm_id
JOIN icustays ie
    ON sc.subject_id = ie.subject_id
    AND sc.hadm_id = ie.hadm_id
    AND sc.icustay_id = ie.icustay_id
    AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
JOIN weight_4bin w
    ON sc.icustay_id = w.icustay_id;

-- Add indexes
CREATE INDEX idx_demographics_subject ON demographics(subject_id);
CREATE INDEX idx_demographics_hadm ON demographics(hadm_id);
CREATE INDEX idx_demographics_icustay ON demographics(icustay_id);

SELECT COUNT(DISTINCT subject_id) FROM demographics WHERE mortality_90day = 1;

SELECT AVG(weight) FROM demographics;

SELECT * FROM demographics;


-- Create demographics table with imputed weights
DROP TABLE IF EXISTS demographics_imputed;
CREATE TABLE demographics_imputed AS
SELECT 
    d.subject_id,
    d.hadm_id,
    d.icustay_id,
    d.earliestOnset,
    d.age,
    d.gender,
    d.race_white,
    d.race_black,
    d.race_asian,
    d.race_latino,
    d.race_other,
    d.mortality_90day,
    d.death,
    d.hour_offset,
    -- Impute weight with patient's mean weight
    COALESCE(d.weight, pmw.mean_weight) AS weight,
    -- Add flag to indicate imputed values
    CASE WHEN d.weight IS NULL THEN 1 ELSE 0 END AS weight_imputed
FROM demographics d
LEFT JOIN (
    SELECT 
        subject_id,
        hadm_id,
        icustay_id,
        AVG(weight) AS mean_weight
    FROM demographics
    WHERE weight IS NOT NULL
    GROUP BY subject_id, hadm_id, icustay_id
) pmw
    ON d.subject_id = pmw.subject_id
    AND d.hadm_id = pmw.hadm_id
    AND d.icustay_id = pmw.icustay_id;

-- Add indexes
CREATE INDEX idx_demographics_imputed_subject ON demographics_imputed(subject_id);
CREATE INDEX idx_demographics_imputed_hadm ON demographics_imputed(hadm_id);
CREATE INDEX idx_demographics_imputed_icustay ON demographics_imputed(icustay_id);

SELECT * FROM demographics_imputed;