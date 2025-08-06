USE mimiciii4;


CREATE TABLE gcs_base AS 
SELECT 
sc.subject_id,
sc.hadm_id,
sc.icustay_id,
sc.earliestOnset,
pvt.charttime,
MAX(CASE WHEN pvt.itemid = 454 THEN pvt.valuenum ELSE NULL END) AS GCSMotor,
MAX(CASE WHEN pvt.itemid = 723 THEN pvt.valuenum ELSE NULL END) AS GCSVerbal,
MAX(CASE WHEN pvt.itemid = 184 THEN pvt.valuenum ELSE NULL END) AS GCSEyes,
CASE
WHEN MAX(CASE WHEN pvt.itemid = 723 THEN pvt.valuenum ELSE NULL END) = 0 THEN 1
ELSE 0
END AS EndoTrachFlag,
ROW_NUMBER() OVER (PARTITION BY pvt.icustay_id ORDER BY pvt.charttime ASC) AS rn
FROM (
SELECT 
l.icustay_id,
CASE
WHEN l.itemid IN (723, 223900) THEN 723
WHEN l.itemid IN (454, 223901) THEN 454
WHEN l.itemid IN (184, 220739) THEN 184
ELSE l.itemid
END AS itemid,
CASE
WHEN l.itemid = 723 AND l.value = '1.0 ET/Trach' THEN 0
WHEN l.itemid = 223900 AND l.value = 'No Response-ETT' THEN 0
ELSE l.valuenum
END AS valuenum,
l.charttime
FROM chartevents l
WHERE l.itemid IN (184, 454, 723, 223900, 223901, 220739)
AND l.icustay_id IS NOT NULL
AND (l.error IS NULL OR l.error = 0)
) pvt
JOIN (
SELECT 
sc.subject_id,
sc.hadm_id,
sc.icustay_id,
sc.earliestOnset
FROM cohort sc
JOIN icustays i
ON sc.subject_id = i.subject_id
AND sc.hadm_id = i.hadm_id
AND sc.earliestOnset BETWEEN i.intime AND i.outtime
) sc
ON pvt.icustay_id = sc.icustay_id
WHERE pvt.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
GROUP BY sc.subject_id, sc.hadm_id, sc.icustay_id, sc.earliestOnset, pvt.charttime;

CREATE INDEX idx_gcs_base_icustay ON gcs_base(icustay_id);
CREATE INDEX idx_gcs_base_rn ON gcs_base(icustay_id, rn);
CREATE INDEX idx_gcs_base_charttime ON gcs_base(charttime);
CREATE INDEX idx_gcs_base_subject ON gcs_base(subject_id);

CREATE TABLE gcs_calculated AS 
SELECT 
b.subject_id,
b.hadm_id,
b.icustay_id,
b.earliestOnset,
b.charttime,
b.GCSMotor,
b.GCSVerbal,
b.GCSEyes,
b.EndoTrachFlag,
b2.GCSMotor AS GCSMotorPrev,
b2.GCSVerbal AS GCSVerbalPrev,
b2.GCSEyes AS GCSEyesPrev,
CASE
WHEN b.GCSVerbal = 0 THEN 15
WHEN b.GCSVerbal IS NULL AND b2.GCSVerbal = 0 THEN 15
WHEN b2.GCSVerbal = 0 THEN
COALESCE(b.GCSMotor, 6) + COALESCE(b.GCSVerbal, 5) + COALESCE(b.GCSEyes, 4)
ELSE
COALESCE(b.GCSMotor, COALESCE(b2.GCSMotor, 6)) +
COALESCE(b.GCSVerbal, COALESCE(b2.GCSVerbal, 5)) +
COALESCE(b.GCSEyes, COALESCE(b2.GCSEyes, 4))
END AS GCS
FROM gcs_base b
LEFT JOIN gcs_base b2
ON b.icustay_id = b2.icustay_id
AND b.rn = b2.rn + 1
AND b2.charttime > DATE_SUB(b.charttime, INTERVAL 6 HOUR);

CREATE INDEX idx_gcs_calc_icustay ON gcs_calculated(icustay_id);
CREATE INDEX idx_gcs_calc_gcs ON gcs_calculated(icustay_id, GCS);
CREATE INDEX idx_gcs_calc_subject ON gcs_calculated(subject_id);

CREATE TABLE gcs_ranked AS 
SELECT 
subject_id,
hadm_id,
icustay_id,
earliestOnset,
GCS,
GCSMotor,
GCSVerbal,
GCSEyes,
EndoTrachFlag,
ROW_NUMBER() OVER (PARTITION BY icustay_id ORDER BY GCS ASC) AS IsMinGCS
FROM gcs_calculated;

CREATE TABLE gcs_1 AS 
  SELECT 
  sc.subject_id,
  sc.hadm_id,
  sc.icustay_id,
  sc.earliestOnset,
  COALESCE(gf.GCS, 15) AS min_gcs,
  gf.GCSMotor AS gcs_motor,
  gf.GCSVerbal AS gcs_verbal,
  gf.GCSEyes AS gcs_eyes,
  COALESCE(gf.EndoTrachFlag, 0) AS endotrach_flag
FROM (
  SELECT DISTINCT subject_id, hadm_id, icustay_id, earliestOnset
  FROM cohort
) sc
LEFT JOIN gcs_ranked gf
ON sc.icustay_id = gf.icustay_id
AND gf.IsMinGCS = 1
ORDER BY sc.subject_id, sc.hadm_id, sc.icustay_id;

-- Add final indexes
CREATE INDEX idx_gcs_1_subject ON gcs_1(subject_id);
CREATE INDEX idx_gcs_1_hadm ON gcs_1(hadm_id);
CREATE INDEX idx_gcs_1_icustay ON gcs_1(icustay_id);
CREATE INDEX idx_gcs_1_gcs ON gcs_1(min_gcs);



-- Create GCS base data using ceFiltered and time bins
DROP TABLE IF EXISTS gcs_4bin_base;
CREATE TABLE gcs_4bin_base AS 
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    tb.earliestOnset,
    ce.charttime,
    MAX(CASE WHEN pvt.itemid = 454 THEN pvt.valuenum ELSE NULL END) AS GCSMotor,
    MAX(CASE WHEN pvt.itemid = 723 THEN pvt.valuenum ELSE NULL END) AS GCSVerbal,
    MAX(CASE WHEN pvt.itemid = 184 THEN pvt.valuenum ELSE NULL END) AS GCSEyes,
    CASE
        WHEN MAX(CASE WHEN pvt.itemid = 723 THEN pvt.valuenum ELSE NULL END) = 0 THEN 1
        ELSE 0
    END AS EndoTrachFlag,
    ROW_NUMBER() OVER (PARTITION BY tb.icustay_id, tb.hour_offset ORDER BY ce.charttime ASC) AS rn_within_bin
FROM 4hr_time_bins tb
LEFT JOIN (
    SELECT 
        ce.icustay_id,
        ce.charttime,
        CASE
            WHEN ce.itemid IN (723, 223900) THEN 723
            WHEN ce.itemid IN (454, 223901) THEN 454
            WHEN ce.itemid IN (184, 220739) THEN 184
            ELSE ce.itemid
        END AS itemid,
        CASE
            WHEN ce.itemid = 723 AND ce.value = '1.0 ET/Trach' THEN 0
            WHEN ce.itemid = 223900 AND ce.value = 'No Response-ETT' THEN 0
            ELSE ce.valuenum
        END AS valuenum
    FROM ceFiltered ce
    WHERE ce.itemid IN (184, 454, 723, 223900, 223901, 220739)
        AND ce.valuenum IS NOT NULL
        AND (ce.error IS NULL OR ce.error = 0)
) pvt
    ON tb.icustay_id = pvt.icustay_id
    AND pvt.charttime >= tb.bin_start_time
    AND pvt.charttime < tb.bin_end_time
LEFT JOIN ceFiltered ce
    ON tb.icustay_id = ce.icustay_id
    AND ce.charttime >= tb.bin_start_time
    AND ce.charttime < tb.bin_end_time
    AND ce.itemid IN (184, 454, 723, 223900, 223901, 220739)
WHERE pvt.charttime IS NOT NULL
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
         tb.bin_start_time, tb.bin_end_time, tb.earliestOnset, ce.charttime;

-- Add indexes
CREATE INDEX idx_gcs_4bin_base_icustay ON gcs_4bin_base(icustay_id);
CREATE INDEX idx_gcs_4bin_base_hour ON gcs_4bin_base(hour_offset);
CREATE INDEX idx_gcs_4bin_base_rn ON gcs_4bin_base(icustay_id, hour_offset, rn_within_bin);

-- Create GCS calculated values for each bin
DROP TABLE IF EXISTS gcs_4bin_calculated;
CREATE TABLE gcs_4bin_calculated AS 
SELECT 
    b.subject_id,
    b.hadm_id,
    b.icustay_id,
    b.hour_offset,
    b.bin_start_time,
    b.bin_end_time,
    b.earliestOnset,
    b.charttime,
    b.GCSMotor,
    b.GCSVerbal,
    b.GCSEyes,
    b.EndoTrachFlag,
    -- Get previous bin's values for carry-forward
    prev.GCSMotor AS GCSMotorPrev,
    prev.GCSVerbal AS GCSVerbalPrev,
    prev.GCSEyes AS GCSEyesPrev,
    -- Calculate GCS with carry-forward logic
    CASE
        WHEN b.GCSVerbal = 0 THEN 15
        WHEN b.GCSVerbal IS NULL AND prev.GCSVerbal = 0 THEN 15
        WHEN prev.GCSVerbal = 0 THEN
            COALESCE(b.GCSMotor, 6) + COALESCE(b.GCSVerbal, 5) + COALESCE(b.GCSEyes, 4)
        ELSE
            COALESCE(b.GCSMotor, COALESCE(prev.GCSMotor, 6)) +
            COALESCE(b.GCSVerbal, COALESCE(prev.GCSVerbal, 5)) +
            COALESCE(b.GCSEyes, COALESCE(prev.GCSEyes, 4))
    END AS GCS
FROM gcs_4bin_base b
LEFT JOIN gcs_4bin_base prev
    ON b.icustay_id = prev.icustay_id
    AND b.hour_offset = prev.hour_offset + 4  -- Previous 4-hour bin
    AND prev.rn_within_bin = 1                -- Take first measurement from previous bin
WHERE b.rn_within_bin = 1;                    -- Take first measurement from current bin

-- Add indexes
CREATE INDEX idx_gcs_4bin_calc_icustay ON gcs_4bin_calculated(icustay_id);
CREATE INDEX idx_gcs_4bin_calc_hour ON gcs_4bin_calculated(hour_offset);
CREATE INDEX idx_gcs_4bin_calc_gcs ON gcs_4bin_calculated(icustay_id, GCS);

-- Create aggregated GCS for each time bin
DROP TABLE IF EXISTS gcs_4bin_aggregated;
CREATE TABLE gcs_4bin_aggregated AS
SELECT 
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    tb.earliestOnset,
    -- GCS aggregations
    MIN(gc.GCS) AS min_gcs,
    MAX(gc.GCS) AS max_gcs,
    AVG(gc.GCS) AS avg_gcs,
    COUNT(gc.GCS) AS gcs_count,
    -- Component aggregations
    MIN(gc.GCSMotor) AS min_gcs_motor,
    MAX(gc.GCSMotor) AS max_gcs_motor,
    AVG(gc.GCSMotor) AS avg_gcs_motor,
    
    MIN(gc.GCSVerbal) AS min_gcs_verbal,
    MAX(gc.GCSVerbal) AS max_gcs_verbal,
    AVG(gc.GCSVerbal) AS avg_gcs_verbal,
    
    MIN(gc.GCSEyes) AS min_gcs_eyes,
    MAX(gc.GCSEyes) AS max_gcs_eyes,
    AVG(gc.GCSEyes) AS avg_gcs_eyes,
    -- EndoTracheal flag (1 if any measurement shows intubation)
    MAX(gc.EndoTrachFlag) AS endotrach_flag

FROM 4hr_time_bins tb
LEFT JOIN gcs_4bin_calculated gc
    ON tb.icustay_id = gc.icustay_id
    AND tb.hour_offset = gc.hour_offset
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset,
         tb.bin_start_time, tb.bin_end_time, tb.earliestOnset
ORDER BY tb.icustay_id, tb.hour_offset;

-- Add indexes
CREATE INDEX idx_gcs_4bin_agg_icustay ON gcs_4bin_aggregated(icustay_id);
CREATE INDEX idx_gcs_4bin_agg_hour ON gcs_4bin_aggregated(hour_offset);
CREATE INDEX idx_gcs_4bin_agg_gcs ON gcs_4bin_aggregated(min_gcs);

-- Create final GCS table with imputation
DROP TABLE IF EXISTS gcs_4bin_imputed;
CREATE TABLE gcs_4bin_imputed AS
SELECT 
    ga.*,
    -- Imputed GCS values (forward fill, then clinical defaults)
    COALESCE(
        ga.min_gcs,
        LAG(ga.min_gcs, 1) OVER (PARTITION BY ga.icustay_id ORDER BY ga.hour_offset),
        LAG(ga.min_gcs, 2) OVER (PARTITION BY ga.icustay_id ORDER BY ga.hour_offset),
        15  -- Normal GCS default
    ) AS min_gcs_imputed,
    
    COALESCE(
        ga.avg_gcs,
        LAG(ga.avg_gcs, 1) OVER (PARTITION BY ga.icustay_id ORDER BY ga.hour_offset),
        LAG(ga.avg_gcs, 2) OVER (PARTITION BY ga.icustay_id ORDER BY ga.hour_offset),
        15  -- Normal GCS default
    ) AS avg_gcs_imputed,
    -- Imputation flags
    CASE WHEN ga.min_gcs IS NULL THEN 1 ELSE 0 END AS gcs_imputed
    
FROM gcs_4bin_aggregated ga
ORDER BY ga.icustay_id, ga.hour_offset;

-- Add final indexes
CREATE INDEX idx_gcs_4bin_imp_icustay ON gcs_4bin_imputed(icustay_id);
CREATE INDEX idx_gcs_4bin_imp_hour ON gcs_4bin_imputed(hour_offset);
CREATE INDEX idx_gcs_4bin_imp_gcs ON gcs_4bin_imputed(min_gcs_imputed);
CREATE INDEX idx_gcs_4bin_imp_composite ON gcs_4bin_imputed(subject_id, hadm_id, icustay_id);

-- Verification queries
SELECT * from gcs_4bin_imputed;


