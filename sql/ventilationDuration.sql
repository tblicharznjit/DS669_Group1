CREATE TABLE ventilation_durations AS
WITH ventilationClassification AS (
  SELECT
    sc.icustay_id,
    ce.charttime,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 720 AND ce.value != 'Other/Remarks' THEN 1
        WHEN ce.itemid = 223848 AND ce.value != 'Other' THEN 1
        WHEN ce.itemid = 223849 THEN 1
        WHEN ce.itemid = 467 AND ce.value = 'Ventilator' THEN 1
        WHEN ce.itemid IN (
          445, 448, 449, 450, 1340, 1486, 1600, 224687, -- minute volume
          639, 654, 681, 682, 683, 684, 224685, 224684, 224686, -- tidal volume
          218, 436, 535, 444, 459, 224697, 224695, 224696, 224746, 224747, -- RespPressure
          221, 1, 1211, 1655, 2000, 226873, 224738, 224419, 224750, 227187, -- Insp pressure
          543, -- PlateauPressure
          5865, 5866, 224707, 224709, 224705, 224706, -- APRV pressure
          60, 437, 505, 506, 686, 220339, 224700, -- PEEP
          3459, -- high pressure relief
          501, 502, 503, 224702, -- PCV
          223, 667, 668, 669, 670, 671, 672, -- TCPCV
          224701 -- PSVlevel
        ) THEN 1
        ELSE 0
      END
    ) AS MechVent,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 226732 AND ce.value IN (
          'Nasal cannula', 'Face tent', 'Aerosol-cool', 'Trach mask ',
          'High flow neb', 'Non-rebreather', 'Venti mask ', 'Medium conc mask ',
          'T-piece', 'High flow nasal cannula', 'Ultrasonic neb', 'Vapomist'
        ) THEN 1
        WHEN ce.itemid = 467 AND ce.value IN (
          'Cannula', 'Nasal Cannula', 'Face Tent', 'Aerosol-Cool', 'Trach Mask',
          'Hi Flow Neb', 'Non-Rebreather', 'Venti Mask', 'Medium Conc Mask',
          'Vapotherm', 'T-Piece', 'Hood', 'Hut', 'TranstrachealCat',
          'Heated Neb', 'Ultrasonic Neb'
        ) THEN 1
        ELSE 0
      END
    ) AS OxygenTherapy,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 640 AND ce.value IN ('Extubated', 'Self Extubation') THEN 1
        ELSE 0
      END
    ) AS Extubated,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 640 AND ce.value = 'Self Extubation' THEN 1
        ELSE 0
      END
    ) AS SelfExtubated
  FROM chartevents ce
  JOIN cohort sc
    ON ce.subject_id = sc.subject_id
    AND ce.hadm_id = sc.hadm_id
    AND ce.icustay_id = sc.icustay_id
    AND sc.earliestOnset BETWEEN (
      SELECT intime FROM icustays i WHERE i.icustay_id = ce.icustay_id
    ) AND (
      SELECT outtime FROM icustays i WHERE i.icustay_id = ce.icustay_id
    )
  WHERE ce.value IS NOT NULL
  AND (ce.error IS NULL OR ce.error = 0)
  AND ce.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
  AND ce.itemid IN (
    720, 223849, -- vent mode
    223848, -- vent type
    445, 448, 449, 450, 1340, 1486, 1600, 224687, -- minute volume
    639, 654, 681, 682, 683, 684, 224685, 224684, 224686, -- tidal volume
    218, 436, 535, 444, 459, 224697, 224695, 224696, 224746, 224747, -- RespPressure
    221, 1, 1211, 1655, 2000, 226873, 224738, 224419, 224750, 227187, -- Insp pressure
    543, -- PlateauPressure
    5865, 5866, 224707, 224709, 224705, 224706, -- APRV pressure
    60, 437, 505, 506, 686, 220339, 224700, -- PEEP
    3459, -- high pressure relief
    501, 502, 503, 224702, -- PCV
    223, 667, 668, 669, 670, 671, 672, -- TCPCV
    224701, -- PSVlevel
    640, -- extubated
    468, 469, 470, 471, 227287, 226732, 223834, -- oxygen therapy
    467 -- O2 Delivery Device
  )
  GROUP BY sc.icustay_id, ce.charttime
  
  UNION DISTINCT
  
  SELECT
    sc.icustay_id,
    pm.starttime AS charttime,
    0 AS MechVent,
    0 AS OxygenTherapy,
    1 AS Extubated,
    CASE WHEN pm.itemid = 225468 THEN 1 ELSE 0 END AS SelfExtubated
  FROM procedureevents_mv pm
  JOIN cohort sc
    ON pm.subject_id = sc.subject_id
    AND pm.hadm_id = sc.hadm_id
    AND pm.icustay_id = sc.icustay_id
    AND sc.earliestOnset BETWEEN (
      SELECT intime FROM icustays i WHERE i.icustay_id = pm.icustay_id
    ) AND (
      SELECT outtime FROM icustays i WHERE i.icustay_id = pm.icustay_id
    )
  WHERE pm.itemid IN (
    227194, -- Extubation
    225468, -- Unplanned Extubation (patient-initiated)
    225477 -- Unplanned Extubation (non-patient initiated)
  )
),
vd0 AS (
  SELECT
    icustay_id,
    charttime,
    CASE
      WHEN MechVent = 1 THEN
        LAG(charttime, 1) OVER (PARTITION BY icustay_id, MechVent ORDER BY charttime)
      ELSE NULL
    END AS charttime_lag,
    MechVent,
    OxygenTherapy,
    Extubated,
    SelfExtubated
  FROM ventilationClassification
),
vd1 AS (
  SELECT
    icustay_id,
    charttime_lag,
    charttime,
    MechVent,
    OxygenTherapy,
    Extubated,
    SelfExtubated,
    CASE
      WHEN MechVent = 1 THEN
        TIMESTAMPDIFF(MINUTE, charttime_lag, charttime) / 60.0
      ELSE NULL
    END AS ventduration,
    LAG(Extubated, 1) OVER (
      PARTITION BY icustay_id, CASE WHEN MechVent = 1 OR Extubated = 1 THEN 1 ELSE 0 END
      ORDER BY charttime
    ) AS ExtubatedLag,
    CASE
      WHEN LAG(Extubated, 1) OVER (
        PARTITION BY icustay_id, CASE WHEN MechVent = 1 OR Extubated = 1 THEN 1 ELSE 0 END
        ORDER BY charttime
      ) = 1 THEN 1
      WHEN MechVent = 0 AND OxygenTherapy = 1 THEN 1
      WHEN charttime > DATE_ADD(charttime_lag, INTERVAL 8 HOUR) THEN 1
      ELSE 0
    END AS newvent
  FROM vd0
),
vd2 AS (
  SELECT
    vd1.*,
    CASE
      WHEN MechVent = 1 OR Extubated = 1 THEN
        SUM(newvent) OVER (PARTITION BY icustay_id ORDER BY charttime)
      ELSE NULL
    END AS ventnum
  FROM vd1
)
SELECT
  icustay_id,
  ROW_NUMBER() OVER (PARTITION BY icustay_id ORDER BY ventnum) AS ventnum,
  MIN(charttime) AS starttime,
  MAX(charttime) AS endtime,
  TIMESTAMPDIFF(MINUTE, MIN(charttime), MAX(charttime)) / 60.0 AS duration_hours
FROM vd2
WHERE ventnum IS NOT NULL
GROUP BY icustay_id, ventnum
HAVING MIN(charttime) != MAX(charttime)
  AND MAX(MechVent) = 1
ORDER BY icustay_id, ventnum;






-- Create ventilation classification in 4-hour bins
DROP TABLE IF EXISTS ventilation_4bin;
CREATE TABLE ventilation_4bin AS
WITH ventilationClassification AS (
  SELECT
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    tb.earliestOnset,
    ce.charttime,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 720 AND ce.value != 'Other/Remarks' THEN 1
        WHEN ce.itemid = 223848 AND ce.value != 'Other' THEN 1
        WHEN ce.itemid = 223849 THEN 1
        WHEN ce.itemid = 467 AND ce.value = 'Ventilator' THEN 1
        WHEN ce.itemid IN (
          445, 448, 449, 450, 1340, 1486, 1600, 224687, -- minute volume
          639, 654, 681, 682, 683, 684, 224685, 224684, 224686, -- tidal volume
          218, 436, 535, 444, 459, 224697, 224695, 224696, 224746, 224747, -- RespPressure
          221, 1, 1211, 1655, 2000, 226873, 224738, 224419, 224750, 227187, -- Insp pressure
          543, -- PlateauPressure
          5865, 5866, 224707, 224709, 224705, 224706, -- APRV pressure
          60, 437, 505, 506, 686, 220339, 224700, -- PEEP
          3459, -- high pressure relief
          501, 502, 503, 224702, -- PCV
          223, 667, 668, 669, 670, 671, 672, -- TCPCV
          224701 -- PSVlevel
        ) THEN 1
        ELSE 0
      END
    ) AS MechVent,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 226732 AND ce.value IN (
          'Nasal cannula', 'Face tent', 'Aerosol-cool', 'Trach mask ',
          'High flow neb', 'Non-rebreather', 'Venti mask ', 'Medium conc mask ',
          'T-piece', 'High flow nasal cannula', 'Ultrasonic neb', 'Vapomist'
        ) THEN 1
        WHEN ce.itemid = 467 AND ce.value IN (
          'Cannula', 'Nasal Cannula', 'Face Tent', 'Aerosol-Cool', 'Trach Mask',
          'Hi Flow Neb', 'Non-Rebreather', 'Venti Mask', 'Medium Conc Mask',
          'Vapotherm', 'T-Piece', 'Hood', 'Hut', 'TranstrachealCat',
          'Heated Neb', 'Ultrasonic Neb'
        ) THEN 1
        ELSE 0
      END
    ) AS OxygenTherapy,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 640 AND ce.value IN ('Extubated', 'Self Extubation') THEN 1
        ELSE 0
      END
    ) AS Extubated,
    MAX(
      CASE
        WHEN ce.itemid IS NULL OR ce.value IS NULL THEN 0
        WHEN ce.itemid = 640 AND ce.value = 'Self Extubation' THEN 1
        ELSE 0
      END
    ) AS SelfExtubated
  FROM 4hr_time_bins tb
  LEFT JOIN ceFiltered ce
    ON tb.icustay_id = ce.icustay_id
    AND ce.charttime >= tb.bin_start_time
    AND ce.charttime < tb.bin_end_time
    AND ce.itemid IN (
      720, 223849, -- vent mode
      223848, -- vent type
      445, 448, 449, 450, 1340, 1486, 1600, 224687, -- minute volume
      639, 654, 681, 682, 683, 684, 224685, 224684, 224686, -- tidal volume
      218, 436, 535, 444, 459, 224697, 224695, 224696, 224746, 224747, -- RespPressure
      221, 1, 1211, 1655, 2000, 226873, 224738, 224419, 224750, 227187, -- Insp pressure
      543, -- PlateauPressure
      5865, 5866, 224707, 224709, 224705, 224706, -- APRV pressure
      60, 437, 505, 506, 686, 220339, 224700, -- PEEP
      3459, -- high pressure relief
      501, 502, 503, 224702, -- PCV
      223, 667, 668, 669, 670, 671, 672, -- TCPCV
      224701, -- PSVlevel
      640, -- extubated
      468, 469, 470, 471, 227287, 226732, 223834, -- oxygen therapy
      467 -- O2 Delivery Device
    )
    AND ce.value IS NOT NULL
    AND (ce.error IS NULL OR ce.error = 0)
  GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, 
           tb.bin_start_time, tb.bin_end_time, tb.earliestOnset, ce.charttime
  
  UNION ALL
  
  SELECT
    tb.subject_id,
    tb.hadm_id,
    tb.icustay_id,
    tb.hour_offset,
    tb.bin_start_time,
    tb.bin_end_time,
    tb.earliestOnset,
    pm.starttime AS charttime,
    0 AS MechVent,
    0 AS OxygenTherapy,
    1 AS Extubated,
    CASE WHEN pm.itemid = 225468 THEN 1 ELSE 0 END AS SelfExtubated
  FROM 4hr_time_bins tb
  LEFT JOIN procedureevents_mv pm
    ON tb.icustay_id = pm.icustay_id
    AND pm.starttime >= tb.bin_start_time
    AND pm.starttime < tb.bin_end_time
    AND pm.itemid IN (
      227194, -- Extubation
      225468, -- Unplanned Extubation (patient-initiated)
      225477 -- Unplanned Extubation (non-patient initiated)
    )
),
-- Aggregate by time bins
ventilation_bin_aggregated AS (
  SELECT
    subject_id,
    hadm_id,
    icustay_id,
    hour_offset,
    bin_start_time,
    bin_end_time,
    earliestOnset,
    MAX(MechVent) AS MechVent,
    MAX(OxygenTherapy) AS OxygenTherapy,
    MAX(Extubated) AS Extubated,
    MAX(SelfExtubated) AS SelfExtubated,
    COUNT(CASE WHEN MechVent = 1 THEN 1 END) AS vent_measurements,
    COUNT(CASE WHEN OxygenTherapy = 1 THEN 1 END) AS oxygen_measurements,
    COUNT(CASE WHEN Extubated = 1 THEN 1 END) AS extubation_events
  FROM ventilationClassification
  GROUP BY subject_id, hadm_id, icustay_id, hour_offset, 
           bin_start_time, bin_end_time, earliestOnset
),
-- Add ventilation status tracking
ventilation_with_status AS (
  SELECT
    *,
    -- Determine primary ventilation status for this bin
    CASE
      WHEN MechVent = 1 THEN 'Mechanical_Ventilation'
      WHEN OxygenTherapy = 1 THEN 'Oxygen_Therapy'
      WHEN Extubated = 1 THEN 'Extubated'
      ELSE 'No_Support'
    END AS vent_status,
    -- Track ventilation changes
    LAG(MechVent, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS prev_mech_vent,
    LEAD(MechVent, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) AS next_mech_vent,
    -- Calculate ventilation episode markers
    CASE
      WHEN MechVent = 1 AND LAG(MechVent, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) = 0 THEN 1
      WHEN MechVent = 1 AND LAG(MechVent, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) IS NULL THEN 1
      ELSE 0
    END AS vent_start,
    CASE
      WHEN MechVent = 0 AND LAG(MechVent, 1) OVER (PARTITION BY icustay_id ORDER BY hour_offset) = 1 THEN 1
      ELSE 0
    END AS vent_end
  FROM ventilation_bin_aggregated
)
SELECT
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  MechVent,
  OxygenTherapy,
  Extubated,
  SelfExtubated,
  vent_status,
  vent_measurements,
  oxygen_measurements,
  extubation_events,
  vent_start,
  vent_end,
  -- Calculate cumulative ventilation hours up to this bin
  SUM(CASE WHEN MechVent = 1 THEN 4 ELSE 0 END) 
    OVER (PARTITION BY icustay_id ORDER BY hour_offset 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_vent_hours,
  -- Calculate total ventilation episodes up to this bin
  SUM(vent_start) 
    OVER (PARTITION BY icustay_id ORDER BY hour_offset 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_vent_episodes      
FROM ventilation_with_status
ORDER BY icustay_id, hour_offset;
-- Add indexes
CREATE INDEX idx_vent_4bin_icustay ON ventilation_4bin(icustay_id);
CREATE INDEX idx_vent_4bin_hour ON ventilation_4bin(hour_offset);
CREATE INDEX idx_vent_4bin_status ON ventilation_4bin(vent_status);
CREATE INDEX idx_vent_4bin_mech ON ventilation_4bin(MechVent);


SELECT * FROM ventilation_4bin;

