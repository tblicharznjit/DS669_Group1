-- Create RBC transfusions table
DROP TABLE IF EXISTS rbc_transfusions_4bin;
CREATE TABLE rbc_transfusions_4bin AS
-- CareVue RBC
SELECT
    icustay_id,
    charttime,
    CASE
        WHEN amount IS NOT NULL THEN amount
        WHEN stopped IS NOT NULL THEN 0
        ELSE 375  -- Default RBC unit volume in mL
    END AS rbc_amount
FROM inputevents_cv
WHERE itemid IN (30179, 30001, 30004)  -- PRBC itemids
    AND icustay_id IS NOT NULL
    AND (amount > 0 OR stopped IS NOT NULL)
UNION ALL
-- MetaVision RBC
SELECT
    icustay_id,
    endtime AS charttime,
    amount AS rbc_amount
FROM inputevents_mv
WHERE itemid = 225168  -- Packed Red Blood Cells
    AND amount > 0
    AND icustay_id IS NOT NULL;

CREATE INDEX idx_rbc_icustay ON rbc_transfusions_4bin(icustay_id);
CREATE INDEX idx_rbc_charttime ON rbc_transfusions_4bin(charttime);

-- Create FFP transfusions table
DROP TABLE IF EXISTS ffp_transfusions_4bin;
CREATE TABLE ffp_transfusions_4bin AS
-- CareVue FFP
SELECT
    icustay_id,
    charttime,
    CASE
        WHEN amount IS NOT NULL THEN amount
        WHEN stopped IS NOT NULL THEN 0
        ELSE 200  -- Default FFP unit volume in mL
    END AS ffp_amount
FROM inputevents_cv
WHERE itemid IN (30005, 30180)  -- FFP itemids
    AND icustay_id IS NOT NULL
    AND (amount > 0 OR stopped IS NOT NULL)
UNION ALL
-- MetaVision FFP
SELECT
    icustay_id,
    endtime AS charttime,
    amount AS ffp_amount
FROM inputevents_mv
WHERE itemid = 220970  -- Fresh Frozen Plasma
    AND amount > 0
    AND icustay_id IS NOT NULL;

CREATE INDEX idx_ffp_icustay ON ffp_transfusions_4bin(icustay_id);
CREATE INDEX idx_ffp_charttime ON ffp_transfusions_4bin(charttime);

-- Create crystalloid boluses table (already exists, but ensuring consistency)
DROP TABLE IF EXISTS crystalloid_boluses_full;
CREATE TABLE crystalloid_boluses_full AS
-- MetaVision crystalloids
SELECT
    icustay_id,
    starttime AS charttime,
    ROUND(CASE
        WHEN amountuom = 'L' THEN amount * 1000.0
        WHEN amountuom = 'ml' THEN amount
        ELSE NULL
    END) AS crystalloid_amount
FROM inputevents_mv
WHERE itemid IN (
    225158, 225828, 225944, 225797, 225159, 225823, 225825, 225827, 225941, 226089
)
AND statusdescription != 'Rewritten'
AND amount IS NOT NULL
AND amount > 0
AND (
    (rate IS NOT NULL AND rateuom = 'mL/hour' AND rate > 248)
    OR (rate IS NOT NULL AND rateuom = 'mL/min' AND rate > (248/60.0))
    OR (rate IS NULL AND amountuom = 'L' AND amount > 0.248)
    OR (rate IS NULL AND amountuom = 'ml' AND amount > 248)
)
UNION ALL
-- CareVue crystalloids
SELECT
    icustay_id,
    charttime,
    ROUND(amount) AS crystalloid_amount
FROM inputevents_cv
WHERE itemid IN (
    30015, 30018, 30020, 30021, 30058, 30060, 30061, 30063, 30065, 30159, 30160, 30169, 30190,
    40850, 41491, 42639, 42187, 43819, 41430, 40712, 44160, 42383, 42297, 42453, 40872, 41915,
    41490, 46501, 45045, 41984, 41371, 41582, 41322, 40778, 41896, 41428, 43936, 44200, 41619,
    40424, 41457, 41581, 42844, 42429, 41356, 40532, 42548, 44184, 44521, 44741, 44126, 44110,
    44633, 44983, 44815, 43986, 45079, 46781, 45155, 43909, 41467, 44367, 41743, 40423, 44263,
    42749, 45480, 44491, 41695, 46169, 41580, 41392, 45989, 45137, 45154, 44053, 41416, 44761,
    41237, 44426, 43975, 44894, 41380, 42671
)
AND amount > 248
AND amount <= 2000
AND amountuom = 'ml';

CREATE INDEX idx_crystalloid_full_icustay ON crystalloid_boluses_full(icustay_id);
CREATE INDEX idx_crystalloid_full_charttime ON crystalloid_boluses_full(charttime);

-- Create colloid boluses table
DROP TABLE IF EXISTS colloid_boluses_full;
CREATE TABLE colloid_boluses_full AS
-- MetaVision colloids
SELECT
    icustay_id,
    starttime AS charttime,
    ROUND(CASE
        WHEN amountuom = 'L' THEN amount * 1000.0
        WHEN amountuom = 'ml' THEN amount
        ELSE NULL
    END) AS colloid_amount
FROM inputevents_mv
WHERE itemid IN (220864, 220862, 225174, 225795, 225796)
AND statusdescription != 'Rewritten'
AND amount IS NOT NULL
AND amount > 0
AND (
    (rateuom = 'mL/hour' AND rate > 100)
    OR (rateuom = 'mL/min' AND rate > (100/60.0))
    OR (rateuom = 'mL/kg/hour' AND (rate * patientweight) > 100)
)
UNION ALL
-- CareVue colloids
SELECT
    icustay_id,
    charttime,
    ROUND(amount) AS colloid_amount
FROM inputevents_cv
WHERE itemid IN (
    30008, 30009, 42832, 40548, 45403, 44203, 30181, 46564, 43237, 43353,
    30012, 46313, 30011, 30016, 42975, 42944, 46336, 46729, 40033, 45410, 42731
)
AND amount > 100
AND amount < 2000
UNION ALL
-- ChartEvents colloids
SELECT
    icustay_id,
    charttime,
    ROUND(valuenum) AS colloid_amount
FROM chartevents
WHERE itemid IN (2510, 3087, 6937, 3088)
AND valuenum IS NOT NULL
AND valuenum > 100
AND valuenum < 2000;

CREATE INDEX idx_colloid_full_icustay ON colloid_boluses_full(icustay_id);
CREATE INDEX idx_colloid_full_charttime ON colloid_boluses_full(charttime);

-- Create other IV inputs table
DROP TABLE IF EXISTS other_inputs_4bin;
CREATE TABLE other_inputs_4bin AS
-- MetaVision other inputs
SELECT
    icustay_id,
    starttime AS charttime,
    ROUND(CASE
        WHEN amountuom = 'L' THEN amount * 1000.0
        WHEN amountuom = 'ml' THEN amount
        ELSE amount
    END) AS other_amount
FROM inputevents_mv
WHERE itemid NOT IN (
    -- Exclude already counted items
    225158, 225828, 225944, 225797, 225159, 225823, 225825, 225827, 225941, 226089,  -- Crystalloids
    220864, 220862, 225174, 225795, 225796,  -- Colloids
    225168, 220970  -- Blood products
)
AND amount IS NOT NULL
AND amount > 0
AND amount < 5000
AND statusdescription != 'Rewritten'
UNION ALL
-- CareVue other inputs
SELECT
    icustay_id,
    charttime,
    ROUND(amount) AS other_amount
FROM inputevents_cv
WHERE itemid NOT IN (
    -- Exclude already counted items (crystalloids)
    30015, 30018, 30020, 30021, 30058, 30060, 30061, 30063, 30065, 30159, 30160, 30169, 30190,
    40850, 41491, 42639, 42187, 43819, 41430, 40712, 44160, 42383, 42297, 42453, 40872, 41915,
    41490, 46501, 45045, 41984, 41371, 41582, 41322, 40778, 41896, 41428, 43936, 44200, 41619,
    40424, 41457, 41581, 42844, 42429, 41356, 40532, 42548, 44184, 44521, 44741, 44126, 44110,
    44633, 44983, 44815, 43986, 45079, 46781, 45155, 43909, 41467, 44367, 41743, 40423, 44263,
    42749, 45480, 44491, 41695, 46169, 41580, 41392, 45989, 45137, 45154, 44053, 41416, 44761,
    41237, 44426, 43975, 44894, 41380, 42671,
    -- Exclude colloids
    30008, 30009, 42832, 40548, 45403, 44203, 30181, 46564, 43237, 43353,
    30012, 46313, 30011, 30016, 42975, 42944, 46336, 46729, 40033, 45410, 42731,
    -- Exclude blood products
    30179, 30001, 30004, 30005, 30180
)
AND amount IS NOT NULL
AND amount > 0
AND amount < 3000
AND amountuom = 'ml';

CREATE INDEX idx_other_inputs_icustay ON other_inputs_4bin(icustay_id);
CREATE INDEX idx_other_inputs_charttime ON other_inputs_4bin(charttime);

-- Create all outputs table
DROP TABLE IF EXISTS all_outputs_4bin;
CREATE TABLE all_outputs_4bin AS
SELECT
    icustay_id,
    charttime,
    ROUND(value) AS output_amount
FROM outputevents
WHERE itemid IN (
  40055, -- "Urine Out Foley"
  43175, -- "Urine ."
  40069, -- "Urine Out Void"
  40094, -- "Urine Out Condom Cath"
  40715, -- "Urine Out Suprapubic"
  40473, -- "Urine Out IleoConduit"
  40085, -- "Urine Out Incontinent"
  40057, -- "Urine Out Rt Nephrostomy"
  40056, -- "Urine Out Lt Nephrostomy"
  40405, -- "Urine Out Other"
  40428, -- "Urine Out Straight Cath"
  40086,--	Urine Out Incontinent
  40096, -- "Urine Out Ureteral Stent #1"
  40651, -- "Urine Out Ureteral Stent #2"
  -- these are the most frequently occurring urine output observations in MetaVision
  226559, -- "Foley"
  226560, -- "Void"
  226561, -- "Condom Cath"
  226584, -- "Ileoconduit"
  226563, -- "Suprapubic"
  226564, -- "R Nephrostomy"
  226565, -- "L Nephrostomy"
  226567, --	Straight Cath
  226557, -- R Ureteral Stent
  226558, -- L Ureteral Stent
  227488, -- GU Irrigant Volume In
  227489  -- GU Irrigant/Urine Volume Out
)
AND value IS NOT NULL
AND value > 0
AND value < 5000;  -- Filter extreme outliers

CREATE INDEX idx_all_outputs_icustay ON all_outputs_4bin(icustay_id);
CREATE INDEX idx_all_outputs_charttime ON all_outputs_4bin(charttime);

-- Create comprehensive fluid balance table
DROP TABLE IF EXISTS fluidBalance_complete_4bin;
CREATE TABLE fluidBalance_complete_4bin AS
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    -- TOTAL INPUTS (all types combined) - FIXED SYNTAX
    (COALESCE(
        (SELECT SUM(rbc_amount) 
         FROM rbc_transfusions_4bin rbc 
         WHERE rbc.icustay_id = tb.icustay_id 
         AND rbc.charttime >= tb.bin_start_time 
         AND rbc.charttime < tb.bin_end_time), 0) +
    COALESCE(
        (SELECT SUM(ffp_amount) 
         FROM ffp_transfusions_4bin ffp 
         WHERE ffp.icustay_id = tb.icustay_id 
         AND ffp.charttime >= tb.bin_start_time 
         AND ffp.charttime < tb.bin_end_time), 0) +
    COALESCE(
        (SELECT SUM(crystalloid_amount) 
         FROM crystalloid_boluses_full cryst 
         WHERE cryst.icustay_id = tb.icustay_id 
         AND cryst.charttime >= tb.bin_start_time 
         AND cryst.charttime < tb.bin_end_time), 0) +
    COALESCE(
        (SELECT SUM(colloid_amount) 
         FROM colloid_boluses_full coll 
         WHERE coll.icustay_id = tb.icustay_id 
         AND coll.charttime >= tb.bin_start_time 
         AND coll.charttime < tb.bin_end_time), 0) +
    COALESCE(
        (SELECT SUM(other_amount) 
         FROM other_inputs_4bin other 
         WHERE other.icustay_id = tb.icustay_id 
         AND other.charttime >= tb.bin_start_time 
         AND other.charttime < tb.bin_end_time), 0)
    ) AS total_input_4hr,
    -- TOTAL OUTPUTS
    COALESCE(
        (SELECT SUM(output_amount) 
         FROM all_outputs_4bin output 
         WHERE output.icustay_id = tb.icustay_id 
         AND output.charttime >= tb.bin_start_time 
         AND output.charttime < tb.bin_end_time), 0
    ) AS total_output_4hr
FROM 4hr_time_bins tb
ORDER BY tb.icustay_id, tb.hour_offset;

-- Add indexes for performance
CREATE INDEX idx_fluid_complete_icustay ON fluidBalance_complete_4bin(icustay_id);
CREATE INDEX idx_fluid_complete_hour ON fluidBalance_complete_4bin(hour_offset);
CREATE INDEX idx_fluid_complete_composite ON fluidBalance_complete_4bin(subject_id, hadm_id, icustay_id, hour_offset);

-- Add net balance calculation
ALTER TABLE fluidBalance_complete_4bin 
ADD COLUMN net_balance_4hr DECIMAL(8,1);

UPDATE fluidBalance_complete_4bin 
SET net_balance_4hr = total_input_4hr - total_output_4hr;

-- Create aggregated table with cumulative calculations
DROP TABLE IF EXISTS fluidBalance_complete_4bin_agg;
CREATE TABLE fluidBalance_complete_4bin_agg AS
SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    hour_offset,
    bin_start_time,
    bin_end_time,
    -- 4-hour values
    total_input_4hr,
    total_output_4hr,
    net_balance_4hr, 
    -- Cumulative values (running totals from ICU admission)
    SUM(total_input_4hr) OVER (
        PARTITION BY icustay_id 
        ORDER BY hour_offset 
        ROWS UNBOUNDED PRECEDING
    ) AS total_input_cumulative,
    
    SUM(total_output_4hr) OVER (
        PARTITION BY icustay_id 
        ORDER BY hour_offset 
        ROWS UNBOUNDED PRECEDING
    ) AS total_output_cumulative,
    
    SUM(net_balance_4hr) OVER (
        PARTITION BY icustay_id 
        ORDER BY hour_offset 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_balance,
    -- 4-hourly output rate (same as total_output_4hr but renamed for clarity)
    total_output_4hr AS hourly_output_4hr,
    -- Hourly output rate (output per hour)
    ROUND(total_output_4hr / 4.0, 1) AS hourly_output_rate
    
FROM fluidBalance_complete_4bin
ORDER BY icustay_id, hour_offset;

-- Add indexes for aggregated table
CREATE INDEX idx_fluid_complete_agg_icustay ON fluidBalance_complete_4bin_agg(icustay_id);
CREATE INDEX idx_fluid_complete_agg_hour ON fluidBalance_complete_4bin_agg(hour_offset);
CREATE INDEX idx_fluid_complete_agg_composite ON fluidBalance_complete_4bin_agg(subject_id, hadm_id, icustay_id, hour_offset);

select AVG(cumulative_balance),AVG(total_output_cumulative),AVG(total_input_cumulative),AVG(hourly_output_4hr) FROM `fluidBalance_complete_4bin_agg`;