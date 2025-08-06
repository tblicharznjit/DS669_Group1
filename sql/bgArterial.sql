CREATE TABLE bloodGasArterial_1 AS
WITH pvt AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    le.charttime,
    CASE
      WHEN le.itemid = 50800 THEN 'SPECIMEN'
      WHEN le.itemid = 50801 THEN 'AADO2'
      WHEN le.itemid = 50802 THEN 'BASEEXCESS'
      WHEN le.itemid = 50803 THEN 'BICARBONATE'
      WHEN le.itemid = 50804 THEN 'TOTALCO2'
      WHEN le.itemid = 50805 THEN 'CARBOXYHEMOGLOBIN'
      WHEN le.itemid = 50806 THEN 'CHLORIDE'
      WHEN le.itemid = 50808 THEN 'CALCIUM'
      WHEN le.itemid = 50809 THEN 'GLUCOSE'
      WHEN le.itemid = 50810 THEN 'HEMATOCRIT'
      WHEN le.itemid = 50811 THEN 'HEMOGLOBIN'
      WHEN le.itemid = 50812 THEN 'INTUBATED'
      WHEN le.itemid = 50813 THEN 'LACTATE'
      WHEN le.itemid = 50814 THEN 'METHEMOGLOBIN'
      WHEN le.itemid = 50815 THEN 'O2FLOW'
      WHEN le.itemid = 50816 THEN 'FIO2'
      WHEN le.itemid = 50817 THEN 'SO2'
      WHEN le.itemid = 50818 THEN 'PCO2'
      WHEN le.itemid = 50819 THEN 'PEEP'
      WHEN le.itemid = 50820 THEN 'PH'
      WHEN le.itemid = 50821 THEN 'PO2'
      WHEN le.itemid = 50822 THEN 'POTASSIUM'
      WHEN le.itemid = 50823 THEN 'REQUIREDO2'
      WHEN le.itemid = 50824 THEN 'SODIUM'
      WHEN le.itemid = 50825 THEN 'TEMPERATURE'
      WHEN le.itemid = 50826 THEN 'TIDALVOLUME'
      WHEN le.itemid = 50827 THEN 'VENTILATIONRATE'
      WHEN le.itemid = 50828 THEN 'VENTILATOR'
      ELSE NULL
    END AS label,
    le.value,
    CASE
      WHEN le.valuenum <= 0 AND le.itemid != 50802 THEN NULL -- Allow negative baseexcess
      WHEN le.itemid = 50810 AND le.valuenum > 100 THEN NULL -- Hematocrit
      WHEN le.itemid = 50816 AND le.valuenum < 20 THEN NULL -- FiO2
      WHEN le.itemid = 50816 AND le.valuenum > 100 THEN NULL -- FiO2
      WHEN le.itemid = 50817 AND le.valuenum > 100 THEN NULL -- SO2
      WHEN le.itemid = 50815 AND le.valuenum > 70 THEN NULL -- O2 flow
      WHEN le.itemid = 50821 AND le.valuenum > 800 THEN NULL -- PO2
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
    AND le.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
    AND le.itemid IN (
      50800, 50801, 50802, 50803, 50804, 50805, 50806, 50808, 50809, 50810,
      50811, 50812, 50813, 50814, 50815, 50816, 50817, 50818, 50819, 50820,
      50821, 50822, 50823, 50824, 50825, 50826, 50827, 50828, 51545
    )
),
blood_gas_first_day AS (
  SELECT 
    pvt.subject_id,
    pvt.hadm_id,
    pvt.icustay_id,
    pvt.earliestOnset,
    pvt.charttime,
    MAX(CASE WHEN pvt.label = 'SPECIMEN' THEN pvt.value ELSE NULL END) AS specimen,
    MAX(CASE WHEN pvt.label = 'AADO2' THEN pvt.valuenum ELSE NULL END) AS aado2,
    MAX(CASE WHEN pvt.label = 'BASEEXCESS' THEN pvt.valuenum ELSE NULL END) AS baseexcess,
    MAX(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate,
    MAX(CASE WHEN pvt.label = 'TOTALCO2' THEN pvt.valuenum ELSE NULL END) AS totalco2,
    MAX(CASE WHEN pvt.label = 'CARBOXYHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS carboxyhemoglobin,
    MAX(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride,
    MAX(CASE WHEN pvt.label = 'CALCIUM' THEN pvt.valuenum ELSE NULL END) AS calcium,
    MAX(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose,
    MAX(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit,
    MAX(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin,
    MAX(CASE WHEN pvt.label = 'INTUBATED' THEN pvt.valuenum ELSE NULL END) AS intubated,
    MAX(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate,
    MAX(CASE WHEN pvt.label = 'METHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS methemoglobin,
    MAX(CASE WHEN pvt.label = 'O2FLOW' THEN pvt.valuenum ELSE NULL END) AS o2flow,
    MAX(CASE WHEN pvt.label = 'FIO2' THEN pvt.valuenum ELSE NULL END) AS fio2,
    MAX(CASE WHEN pvt.label = 'SO2' THEN pvt.valuenum ELSE NULL END) AS so2,
    MAX(CASE WHEN pvt.label = 'PCO2' THEN pvt.valuenum ELSE NULL END) AS pco2,
    MAX(CASE WHEN pvt.label = 'PEEP' THEN pvt.valuenum ELSE NULL END) AS peep,
    MAX(CASE WHEN pvt.label = 'PH' THEN pvt.valuenum ELSE NULL END) AS ph,
    MAX(CASE WHEN pvt.label = 'PO2' THEN pvt.valuenum ELSE NULL END) AS po2,
    MAX(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium,
    MAX(CASE WHEN pvt.label = 'REQUIREDO2' THEN pvt.valuenum ELSE NULL END) AS requiredo2,
    MAX(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium,
    MAX(CASE WHEN pvt.label = 'TEMPERATURE' THEN pvt.valuenum ELSE NULL END) AS temperature,
    MAX(CASE WHEN pvt.label = 'TIDALVOLUME' THEN pvt.valuenum ELSE NULL END) AS tidalvolume,
    MAX(CASE WHEN pvt.label = 'VENTILATIONRATE' THEN pvt.valuenum ELSE NULL END) AS ventilationrate,
    MAX(CASE WHEN pvt.label = 'VENTILATOR' THEN pvt.valuenum ELSE NULL END) AS ventilator
  FROM pvt
  WHERE pvt.label IS NOT NULL
  GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.earliestOnset, pvt.charttime
),
stg_spo2 AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    charttime,
    MAX(CASE WHEN valuenum <= 0 OR valuenum > 100 THEN NULL ELSE valuenum END) AS spo2
  FROM chartevents
  WHERE itemid IN (
    646, -- SpO2
    220277 -- O2 saturation pulseoxymetry
  )
  GROUP BY subject_id, hadm_id, icustay_id, charttime
),
stg_fio2 AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    charttime,
    MAX(
      CASE
        WHEN itemid = 223835 THEN
          CASE
            WHEN valuenum > 0 AND valuenum <= 1 THEN valuenum * 100
            WHEN valuenum > 1 AND valuenum < 21 THEN NULL
            WHEN valuenum >= 21 AND valuenum <= 100 THEN valuenum
            ELSE NULL
          END
        WHEN itemid IN (3420, 3422) THEN valuenum
        WHEN itemid = 190 AND valuenum > 0.20 AND valuenum < 1 THEN valuenum * 100
        ELSE NULL
      END
    ) AS fio2_chartevents
  FROM chartevents
  WHERE itemid IN (
    3420, -- FiO2
    190, -- FiO2 set
    223835, -- Inspired O2 Fraction (FiO2)
    3422 -- FiO2 [measured]
  )
  AND (error IS NULL OR error = 0)
  GROUP BY subject_id, hadm_id, icustay_id, charttime
),
stg2 AS (
  SELECT 
    bg.*,
    ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.charttime ORDER BY s1.charttime DESC) AS lastRowSpO2,
    s1.spo2
  FROM blood_gas_first_day bg
  LEFT JOIN stg_spo2 s1
    ON bg.icustay_id = s1.icustay_id
    AND s1.charttime BETWEEN DATE_SUB(bg.charttime, INTERVAL 2 HOUR) AND bg.charttime
  WHERE bg.po2 IS NOT NULL
),
stg3 AS (
  SELECT 
    bg.*,
    ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.charttime ORDER BY s2.charttime DESC) AS lastRowFiO2,
    s2.fio2_chartevents,
    1 / (1 + EXP(-(
      -0.02544
      + 0.04598 * bg.po2
      + COALESCE(-0.15356 * bg.spo2, -0.15356 * 97.49420 + 0.13429)
      + COALESCE(0.00621 * s2.fio2_chartevents, 0.00621 * 51.49550 + -0.24958)
      + COALESCE(0.10559 * bg.hemoglobin, 0.10559 * 10.32307 + 0.05954)
      + COALESCE(0.13251 * bg.so2, 0.13251 * 93.66539 + -0.23172)
      + COALESCE(-0.01511 * bg.pco2, -0.01511 * 42.08866 + -0.01630)
      + COALESCE(0.01480 * bg.fio2, 0.01480 * 63.97836 + -0.31142)
      + COALESCE(-0.00200 * bg.aado2, -0.00200 * 442.21186 + -0.01328)
      + COALESCE(-0.03220 * bg.bicarbonate, -0.03220 * 22.96894 + -0.06535)
      + COALESCE(0.05384 * bg.totalco2, 0.05384 * 24.72632 + -0.01405)
      + COALESCE(0.08202 * bg.lactate, 0.08202 * 3.06436 + 0.06038)
      + COALESCE(0.10956 * bg.ph, 0.10956 * 7.36233 + -0.00617)
      + COALESCE(0.00848 * bg.o2flow, 0.00848 * 7.59362 + -0.35803)
    ))) AS specimen_prob
  FROM stg2 bg
  LEFT JOIN stg_fio2 s2
    ON bg.icustay_id = s2.icustay_id
    AND s2.charttime BETWEEN DATE_SUB(bg.charttime, INTERVAL 4 HOUR) AND bg.charttime
  WHERE bg.lastRowSpO2 = 1
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  earliestOnset,
  charttime,
  specimen,
  CASE
    WHEN specimen IS NOT NULL THEN specimen
    WHEN specimen_prob > 0.75 THEN 'ART'
    ELSE NULL
  END AS specimen_pred,
  specimen_prob,
  so2,
  spo2,
  po2,
  pco2,
  fio2_chartevents,
  fio2,
  CASE
    WHEN po2 IS NOT NULL
    AND pco2 IS NOT NULL
    AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN (COALESCE(fio2, fio2_chartevents) / 100) * (760 - 47) - (pco2 / 0.8) - po2
    ELSE NULL
  END AS aado2_calc,
  CASE
    WHEN po2 IS NOT NULL AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN 100 * po2 / COALESCE(fio2, fio2_chartevents)
    ELSE NULL
  END AS pao2fio2,
  ph,
  baseexcess,
  bicarbonate,
  totalco2,
  hematocrit,
  hemoglobin,
  carboxyhemoglobin,
  methemoglobin,
  chloride,
  calcium,
  temperature,
  potassium,
  sodium,
  lactate,
  glucose,
  intubated,
  tidalvolume,
  ventilationrate,
  ventilator,
  peep,
  o2flow,
  requiredo2
FROM stg3
WHERE lastRowFiO2 = 1
AND (specimen = 'ART' OR specimen_prob > 0.75)
ORDER BY icustay_id, charttime;



DROP TABLE IF EXISTS bgArterial_4bin_pvt;
CREATE TABLE bgArterial_4bin_pvt AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  tb.bin_start_time,
  tb.bin_end_time,
  tb.earliestOnset,
  le.charttime,
  CASE
    WHEN le.itemid = 50800 THEN 'SPECIMEN'
    WHEN le.itemid = 50801 THEN 'AADO2'
    WHEN le.itemid = 50802 THEN 'BASEEXCESS'
    WHEN le.itemid = 50803 THEN 'BICARBONATE'
    WHEN le.itemid = 50804 THEN 'TOTALCO2'
    WHEN le.itemid = 50805 THEN 'CARBOXYHEMOGLOBIN'
    WHEN le.itemid = 50806 THEN 'CHLORIDE'
    WHEN le.itemid = 50808 THEN 'CALCIUM'
    WHEN le.itemid = 50809 THEN 'GLUCOSE'
    WHEN le.itemid = 50810 THEN 'HEMATOCRIT'
    WHEN le.itemid = 50811 THEN 'HEMOGLOBIN'
    WHEN le.itemid = 50812 THEN 'INTUBATED'
    WHEN le.itemid = 50813 THEN 'LACTATE'
    WHEN le.itemid = 50814 THEN 'METHEMOGLOBIN'
    WHEN le.itemid = 50815 THEN 'O2FLOW'
    WHEN le.itemid = 50816 THEN 'FIO2'
    WHEN le.itemid = 50817 THEN 'SO2'
    WHEN le.itemid = 50818 THEN 'PCO2'
    WHEN le.itemid = 50819 THEN 'PEEP'
    WHEN le.itemid = 50820 THEN 'PH'
    WHEN le.itemid = 50821 THEN 'PO2'
    WHEN le.itemid = 50822 THEN 'POTASSIUM'
    WHEN le.itemid = 50823 THEN 'REQUIREDO2'
    WHEN le.itemid = 50824 THEN 'SODIUM'
    WHEN le.itemid = 50825 THEN 'TEMPERATURE'
    WHEN le.itemid = 50826 THEN 'TIDALVOLUME'
    WHEN le.itemid = 50827 THEN 'VENTILATIONRATE'
    WHEN le.itemid = 50828 THEN 'VENTILATOR'
    ELSE NULL
  END AS label,
  le.value,
  CASE
    WHEN le.valuenum <= 0 AND le.itemid != 50802 THEN NULL -- Allow negative baseexcess
    WHEN le.itemid = 50810 AND le.valuenum > 100 THEN NULL -- Hematocrit
    WHEN le.itemid = 50816 AND le.valuenum < 20 THEN NULL -- FiO2
    WHEN le.itemid = 50816 AND le.valuenum > 100 THEN NULL -- FiO2
    WHEN le.itemid = 50817 AND le.valuenum > 100 THEN NULL -- SO2
    WHEN le.itemid = 50815 AND le.valuenum > 70 THEN NULL -- O2 flow
    WHEN le.itemid = 50821 AND le.valuenum > 800 THEN NULL -- PO2
    ELSE le.valuenum
  END AS valuenum
FROM 4hr_time_bins tb
LEFT JOIN labevents le
  ON tb.subject_id = le.subject_id
  AND tb.hadm_id = le.hadm_id
  AND le.charttime >= tb.bin_start_time
  AND le.charttime < tb.bin_end_time
  AND le.itemid IN (
    50800, 50801, 50802, 50803, 50804, 50805, 50806, 50808, 50809, 50810,
    50811, 50812, 50813, 50814, 50815, 50816, 50817, 50818, 50819, 50820,
    50821, 50822, 50823, 50824, 50825, 50826, 50827, 50828, 51545
  )
WHERE CASE
    WHEN le.itemid = 50800 THEN 'SPECIMEN'
    WHEN le.itemid = 50801 THEN 'AADO2'
    WHEN le.itemid = 50802 THEN 'BASEEXCESS'
    WHEN le.itemid = 50803 THEN 'BICARBONATE'
    WHEN le.itemid = 50804 THEN 'TOTALCO2'
    WHEN le.itemid = 50805 THEN 'CARBOXYHEMOGLOBIN'
    WHEN le.itemid = 50806 THEN 'CHLORIDE'
    WHEN le.itemid = 50808 THEN 'CALCIUM'
    WHEN le.itemid = 50809 THEN 'GLUCOSE'
    WHEN le.itemid = 50810 THEN 'HEMATOCRIT'
    WHEN le.itemid = 50811 THEN 'HEMOGLOBIN'
    WHEN le.itemid = 50812 THEN 'INTUBATED'
    WHEN le.itemid = 50813 THEN 'LACTATE'
    WHEN le.itemid = 50814 THEN 'METHEMOGLOBIN'
    WHEN le.itemid = 50815 THEN 'O2FLOW'
    WHEN le.itemid = 50816 THEN 'FIO2'
    WHEN le.itemid = 50817 THEN 'SO2'
    WHEN le.itemid = 50818 THEN 'PCO2'
    WHEN le.itemid = 50819 THEN 'PEEP'
    WHEN le.itemid = 50820 THEN 'PH'
    WHEN le.itemid = 50821 THEN 'PO2'
    WHEN le.itemid = 50822 THEN 'POTASSIUM'
    WHEN le.itemid = 50823 THEN 'REQUIREDO2'
    WHEN le.itemid = 50824 THEN 'SODIUM'
    WHEN le.itemid = 50825 THEN 'TEMPERATURE'
    WHEN le.itemid = 50826 THEN 'TIDALVOLUME'
    WHEN le.itemid = 50827 THEN 'VENTILATIONRATE'
    WHEN le.itemid = 50828 THEN 'VENTILATOR'
    ELSE NULL
  END IS NOT NULL;

CREATE INDEX idx_bgpvt_ids ON bgArterial_4bin_pvt(subject_id, hadm_id, icustay_id, hour_offset);
CREATE INDEX idx_bgpvt_chart ON bgArterial_4bin_pvt(charttime);


DROP TABLE IF EXISTS bgArterial_4bin_bg;
CREATE TABLE bgArterial_4bin_bg AS
SELECT 
  pvt.subject_id,
  pvt.hadm_id,
  pvt.icustay_id,
  pvt.hour_offset,
  pvt.bin_start_time,
  pvt.bin_end_time,
  pvt.earliestOnset,
  pvt.charttime,
  MAX(CASE WHEN pvt.label = 'SPECIMEN' THEN pvt.value ELSE NULL END) AS specimen,
  MAX(CASE WHEN pvt.label = 'AADO2' THEN pvt.valuenum ELSE NULL END) AS aado2,
  MAX(CASE WHEN pvt.label = 'BASEEXCESS' THEN pvt.valuenum ELSE NULL END) AS baseexcess,
  MAX(CASE WHEN pvt.label = 'BICARBONATE' THEN pvt.valuenum ELSE NULL END) AS bicarbonate,
  MAX(CASE WHEN pvt.label = 'TOTALCO2' THEN pvt.valuenum ELSE NULL END) AS totalco2,
  MAX(CASE WHEN pvt.label = 'CARBOXYHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS carboxyhemoglobin,
  MAX(CASE WHEN pvt.label = 'CHLORIDE' THEN pvt.valuenum ELSE NULL END) AS chloride,
  MAX(CASE WHEN pvt.label = 'CALCIUM' THEN pvt.valuenum ELSE NULL END) AS calcium,
  MAX(CASE WHEN pvt.label = 'GLUCOSE' THEN pvt.valuenum ELSE NULL END) AS glucose,
  MAX(CASE WHEN pvt.label = 'HEMATOCRIT' THEN pvt.valuenum ELSE NULL END) AS hematocrit,
  MAX(CASE WHEN pvt.label = 'HEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS hemoglobin,
  MAX(CASE WHEN pvt.label = 'INTUBATED' THEN pvt.valuenum ELSE NULL END) AS intubated,
  MAX(CASE WHEN pvt.label = 'LACTATE' THEN pvt.valuenum ELSE NULL END) AS lactate,
  MAX(CASE WHEN pvt.label = 'METHEMOGLOBIN' THEN pvt.valuenum ELSE NULL END) AS methemoglobin,
  MAX(CASE WHEN pvt.label = 'O2FLOW' THEN pvt.valuenum ELSE NULL END) AS o2flow,
  MAX(CASE WHEN pvt.label = 'FIO2' THEN pvt.valuenum ELSE NULL END) AS fio2,
  MAX(CASE WHEN pvt.label = 'SO2' THEN pvt.valuenum ELSE NULL END) AS so2,
  MAX(CASE WHEN pvt.label = 'PCO2' THEN pvt.valuenum ELSE NULL END) AS pco2,
  MAX(CASE WHEN pvt.label = 'PEEP' THEN pvt.valuenum ELSE NULL END) AS peep,
  MAX(CASE WHEN pvt.label = 'PH' THEN pvt.valuenum ELSE NULL END) AS ph,
  MAX(CASE WHEN pvt.label = 'PO2' THEN pvt.valuenum ELSE NULL END) AS po2,
  MAX(CASE WHEN pvt.label = 'POTASSIUM' THEN pvt.valuenum ELSE NULL END) AS potassium,
  MAX(CASE WHEN pvt.label = 'REQUIREDO2' THEN pvt.valuenum ELSE NULL END) AS requiredo2,
  MAX(CASE WHEN pvt.label = 'SODIUM' THEN pvt.valuenum ELSE NULL END) AS sodium,
  MAX(CASE WHEN pvt.label = 'TEMPERATURE' THEN pvt.valuenum ELSE NULL END) AS temperature,
  MAX(CASE WHEN pvt.label = 'TIDALVOLUME' THEN pvt.valuenum ELSE NULL END) AS tidalvolume,
  MAX(CASE WHEN pvt.label = 'VENTILATIONRATE' THEN pvt.valuenum ELSE NULL END) AS ventilationrate,
  MAX(CASE WHEN pvt.label = 'VENTILATOR' THEN pvt.valuenum ELSE NULL END) AS ventilator
FROM bgArterial_4bin_pvt pvt
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.hour_offset,
         pvt.bin_start_time, pvt.bin_end_time, pvt.earliestOnset, pvt.charttime;

CREATE INDEX idx_bgbg_ids ON bgArterial_4bin_bg(subject_id, hadm_id, icustay_id, hour_offset);
CREATE INDEX idx_bgbg_chart ON bgArterial_4bin_bg(charttime);
CREATE INDEX idx_bgbg_po2 ON bgArterial_4bin_bg(po2);


DROP TABLE IF EXISTS bgArterial_4bin_spo2;
CREATE TABLE bgArterial_4bin_spo2 AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  ce.charttime,
  MAX(CASE WHEN ce.valuenum <= 0 OR ce.valuenum > 100 THEN NULL ELSE ce.valuenum END) AS spo2
FROM 4hr_time_bins tb
LEFT JOIN ceFiltered ce
  ON tb.icustay_id = ce.icustay_id
  AND ce.charttime >= tb.bin_start_time
  AND ce.charttime < tb.bin_end_time
  AND ce.itemid IN (646, 220277) -- SpO2
  AND (ce.error IS NULL OR ce.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, ce.charttime;

CREATE INDEX idx_spo2_ids ON bgArterial_4bin_spo2(icustay_id, hour_offset);
CREATE INDEX idx_spo2_chart ON bgArterial_4bin_spo2(charttime);


DROP TABLE IF EXISTS bgArterial_4bin_fio2;
CREATE TABLE bgArterial_4bin_fio2 AS
SELECT 
  tb.subject_id,
  tb.hadm_id,
  tb.icustay_id,
  tb.hour_offset,
  ce.charttime,
  MAX(
    CASE
      WHEN ce.itemid = 223835 THEN
        CASE
          WHEN ce.valuenum > 0 AND ce.valuenum <= 1 THEN ce.valuenum * 100
          WHEN ce.valuenum > 1 AND ce.valuenum < 21 THEN NULL
          WHEN ce.valuenum >= 21 AND ce.valuenum <= 100 THEN ce.valuenum
          ELSE NULL
        END
      WHEN ce.itemid IN (3420, 3422) THEN ce.valuenum
      WHEN ce.itemid = 190 AND ce.valuenum > 0.20 AND ce.valuenum < 1 THEN ce.valuenum * 100
      ELSE NULL
    END
  ) AS fio2_chartevents
FROM 4hr_time_bins tb
LEFT JOIN ceFiltered ce
  ON tb.icustay_id = ce.icustay_id
  AND ce.charttime >= tb.bin_start_time
  AND ce.charttime < tb.bin_end_time
  AND ce.itemid IN (3420, 190, 223835, 3422) -- FiO2
  AND (ce.error IS NULL OR ce.error = 0)
GROUP BY tb.subject_id, tb.hadm_id, tb.icustay_id, tb.hour_offset, ce.charttime;

CREATE INDEX idx_fio2_ids ON bgArterial_4bin_fio2(icustay_id, hour_offset);
CREATE INDEX idx_fio2_chart ON bgArterial_4bin_fio2(charttime);


DROP TABLE IF EXISTS bgArterial_4bin_stg2;
CREATE TABLE bgArterial_4bin_stg2 AS
SELECT 
  bg.*,
  ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.hour_offset, bg.charttime ORDER BY s1.charttime DESC) AS lastRowSpO2,
  s1.spo2
FROM bgArterial_4bin_bg bg
LEFT JOIN bgArterial_4bin_spo2 s1
  ON bg.icustay_id = s1.icustay_id
  AND bg.hour_offset = s1.hour_offset
  AND s1.charttime <= bg.charttime
WHERE bg.po2 IS NOT NULL;

CREATE INDEX idx_stg2_ids ON bgArterial_4bin_stg2(icustay_id, hour_offset);
CREATE INDEX idx_stg2_row ON bgArterial_4bin_stg2(lastRowSpO2);

DROP TABLE IF EXISTS bgArterial_4bin_stg3;
CREATE TABLE bgArterial_4bin_stg3 AS
SELECT 
  bg.*,
  ROW_NUMBER() OVER (PARTITION BY bg.icustay_id, bg.hour_offset, bg.charttime ORDER BY s2.charttime DESC) AS lastRowFiO2,
  s2.fio2_chartevents,
  1 / (1 + EXP(-(
    -0.02544
    + 0.04598 * bg.po2
    + COALESCE(-0.15356 * bg.spo2, -0.15356 * 97.49420 + 0.13429)
    + COALESCE(0.00621 * s2.fio2_chartevents, 0.00621 * 51.49550 + -0.24958)
    + COALESCE(0.10559 * bg.hemoglobin, 0.10559 * 10.32307 + 0.05954)
    + COALESCE(0.13251 * bg.so2, 0.13251 * 93.66539 + -0.23172)
    + COALESCE(-0.01511 * bg.pco2, -0.01511 * 42.08866 + -0.01630)
    + COALESCE(0.01480 * bg.fio2, 0.01480 * 63.97836 + -0.31142)
    + COALESCE(-0.00200 * bg.aado2, -0.00200 * 442.21186 + -0.01328)
    + COALESCE(-0.03220 * bg.bicarbonate, -0.03220 * 22.96894 + -0.06535)
    + COALESCE(0.05384 * bg.totalco2, 0.05384 * 24.72632 + -0.01405)
    + COALESCE(0.08202 * bg.lactate, 0.08202 * 3.06436 + 0.06038)
    + COALESCE(0.10956 * bg.ph, 0.10956 * 7.36233 + -0.00617)
    + COALESCE(0.00848 * bg.o2flow, 0.00848 * 7.59362 + -0.35803)
  ))) AS specimen_prob
FROM bgArterial_4bin_stg2 bg
LEFT JOIN bgArterial_4bin_fio2 s2
  ON bg.icustay_id = s2.icustay_id
  AND bg.hour_offset = s2.hour_offset
  AND s2.charttime <= bg.charttime
WHERE bg.lastRowSpO2 = 1;

CREATE INDEX idx_stg3_ids ON bgArterial_4bin_stg3(icustay_id, hour_offset);
CREATE INDEX idx_stg3_row ON bgArterial_4bin_stg3(lastRowFiO2);


DROP TABLE IF EXISTS bloodGasArterial_4bin;
CREATE TABLE bloodGasArterial_4bin AS
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  hour_offset,
  bin_start_time,
  bin_end_time,
  earliestOnset,
  charttime,
  specimen,
  CASE
    WHEN specimen IS NOT NULL THEN specimen
    WHEN specimen_prob > 0.75 THEN 'ART'
    ELSE NULL
  END AS specimen_pred,
  specimen_prob,
  so2,
  spo2,
  po2,
  pco2,
  fio2_chartevents,
  fio2,
  CASE
    WHEN po2 IS NOT NULL
    AND pco2 IS NOT NULL
    AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN (COALESCE(fio2, fio2_chartevents) / 100) * (760 - 47) - (pco2 / 0.8) - po2
    ELSE NULL
  END AS aado2_calc,
  CASE
    WHEN po2 IS NOT NULL AND COALESCE(fio2, fio2_chartevents) IS NOT NULL
    THEN 100 * po2 / COALESCE(fio2, fio2_chartevents)
    ELSE NULL
  END AS pao2fio2,
  ph,
  baseexcess,
  bicarbonate,
  totalco2,
  hematocrit,
  hemoglobin,
  carboxyhemoglobin,
  methemoglobin,
  chloride,
  calcium,
  temperature,
  potassium,
  sodium,
  lactate,
  glucose,
  intubated,
  tidalvolume,
  ventilationrate,
  ventilator,
  peep,
  o2flow,
  requiredo2
FROM bgArterial_4bin_stg3
WHERE lastRowFiO2 = 1
AND (specimen = 'ART' OR specimen_prob > 0.75)
ORDER BY icustay_id, hour_offset, charttime;

-- Add final indexes
CREATE INDEX idx_abg_4bin_icustay ON bloodGasArterial_4bin(icustay_id);
CREATE INDEX idx_abg_4bin_hour ON bloodGasArterial_4bin(hour_offset);
CREATE INDEX idx_abg_4bin_composite ON bloodGasArterial_4bin(subject_id, hadm_id, icustay_id, hour_offset);


SELECT * FROM `bloodGasArterial_4bin`;


DROP TABLE IF EXISTS bloodGasArterial_4bin_agg;
CREATE TABLE bloodGasArterial_4bin_agg AS
WITH abg_binned AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    hour_offset,
    bin_start_time,
    bin_end_time,
    earliestOnset,
    -- Aggregate ABG values within each bin (taking averages for multiple measurements)
    AVG(po2) AS po2_avg,
    MIN(po2) AS po2_min,
    MAX(po2) AS po2_max,
    AVG(pco2) AS pco2_avg,
    MIN(pco2) AS pco2_min,
    MAX(pco2) AS pco2_max,
    AVG(ph) AS ph_avg,
    MIN(ph) AS ph_min,
    MAX(ph) AS ph_max,
    AVG(so2) AS so2_avg,
    AVG(spo2) AS spo2_avg,
    MAX(spo2) AS spo2_max,
    MIN(spo2) AS spo2_min,
    AVG(COALESCE(fio2, fio2_chartevents)) AS fio2_avg,
    MAX(COALESCE(fio2, fio2_chartevents)) AS fio2_max,
    AVG(pao2fio2) AS pao2fio2_avg,
    MIN(pao2fio2) AS pao2fio2_min,
    AVG(lactate) AS lactate_avg,
    MAX(lactate) AS lactate_max,
    AVG(baseexcess) AS baseexcess_avg,
    MIN(baseexcess) AS baseexcess_min,
    MAX(baseexcess) AS baseexcess_max,
    AVG(bicarbonate) AS bicarbonate_avg,
    AVG(totalco2) AS totalco2_avg,
    AVG(aado2_calc) AS aado2_calc_avg,
    AVG(glucose) AS glucose_avg,
    MIN(glucose) AS glucose_min,
    MAX(glucose) AS glucose_max,
    -- Ventilator parameters
    AVG(peep) AS peep_avg,
    MAX(peep) AS peep_max,
    AVG(tidalvolume) AS tidalvolume_avg,
    AVG(ventilationrate) AS ventilationrate_avg,
    MAX(intubated) AS intubated,
    MAX(ventilator) AS ventilator,
    AVG(o2flow) AS o2flow_avg,
    MAX(requiredo2) AS requiredo2,
    -- Lab values
    AVG(hematocrit) AS hematocrit_avg,
    AVG(hemoglobin) AS hemoglobin_avg,
    AVG(potassium) AS potassium_avg,
    AVG(sodium) AS sodium_avg,
    AVG(chloride) AS chloride_avg,
    AVG(calcium) AS calcium_avg,
    AVG(temperature) AS temperature_avg,
    AVG(carboxyhemoglobin) AS carboxyhemoglobin_avg,
    AVG(methemoglobin) AS methemoglobin_avg,
    -- Specimen info - take most recent non-null
    SUBSTRING_INDEX(GROUP_CONCAT(specimen ORDER BY charttime DESC SEPARATOR ','), ',', 1) AS specimen,
    SUBSTRING_INDEX(GROUP_CONCAT(specimen_pred ORDER BY charttime DESC SEPARATOR ','), ',', 1) AS specimen_pred,
    -- Count measurements
    COUNT(*) AS measurements_count,
    COUNT(po2) AS po2_count,
    COUNT(pco2) AS pco2_count,
    COUNT(ph) AS ph_count,
    COUNT(lactate) AS lactate_count,
    COUNT(pao2fio2) AS pao2fio2_count,
    COUNT(glucose) AS glucose_count,
    COUNT(bicarbonate) AS bicarbonate_count,
    COUNT(baseexcess) AS baseexcess_count
    
  FROM bloodGasArterial_4bin
  GROUP BY subject_id, hadm_id, icustay_id, hour_offset, bin_start_time, bin_end_time, earliestOnset
),
-- Calculate patient-level statistics for imputation
patient_stats AS (
  SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    AVG(ph_avg) AS patient_ph_mean,
    AVG(po2_avg) AS patient_po2_mean,
    AVG(pco2_avg) AS patient_pco2_mean,
    AVG(lactate_avg) AS patient_lactate_mean,
    AVG(pao2fio2_avg) AS patient_pao2fio2_mean,
    AVG(baseexcess_avg) AS patient_baseexcess_mean,
    AVG(bicarbonate_avg) AS patient_bicarbonate_mean,
    AVG(fio2_avg) AS patient_fio2_mean,
    AVG(so2_avg) AS patient_so2_mean,
    AVG(spo2_avg) AS patient_spo2_mean,
    AVG(glucose_avg) AS patient_glucose_mean,
    AVG(hematocrit_avg) AS patient_hematocrit_mean,
    AVG(hemoglobin_avg) AS patient_hemoglobin_mean,
    AVG(potassium_avg) AS patient_potassium_mean,
    AVG(sodium_avg) AS patient_sodium_mean,
    AVG(chloride_avg) AS patient_chloride_mean,
    AVG(calcium_avg) AS patient_calcium_mean,
    AVG(temperature_avg) AS patient_temperature_mean
  FROM abg_binned
  WHERE ph_avg IS NOT NULL OR po2_avg IS NOT NULL OR pco2_avg IS NOT NULL
  GROUP BY subject_id, hadm_id, icustay_id
),
-- Population statistics for final fallback
population_stats AS (
  SELECT 
    AVG(ph_avg) AS pop_ph_mean,
    AVG(po2_avg) AS pop_po2_mean,
    AVG(pco2_avg) AS pop_pco2_mean,
    AVG(lactate_avg) AS pop_lactate_mean,
    AVG(pao2fio2_avg) AS pop_pao2fio2_mean,
    AVG(baseexcess_avg) AS pop_baseexcess_mean,
    AVG(bicarbonate_avg) AS pop_bicarbonate_mean,
    AVG(fio2_avg) AS pop_fio2_mean,
    AVG(so2_avg) AS pop_so2_mean,
    AVG(spo2_avg) AS pop_spo2_mean,
    AVG(glucose_avg) AS pop_glucose_mean,
    AVG(hematocrit_avg) AS pop_hematocrit_mean,
    AVG(hemoglobin_avg) AS pop_hemoglobin_mean,
    AVG(potassium_avg) AS pop_potassium_mean,
    AVG(sodium_avg) AS pop_sodium_mean,
    AVG(chloride_avg) AS pop_chloride_mean,
    AVG(calcium_avg) AS pop_calcium_mean,
    AVG(temperature_avg) AS pop_temperature_mean
  FROM abg_binned
  WHERE ph_avg IS NOT NULL OR po2_avg IS NOT NULL OR pco2_avg IS NOT NULL
),
-- Forward/backward fill within patient
filled_values AS (
  SELECT 
    ab.*,
    ps.patient_ph_mean,
    ps.patient_po2_mean,
    ps.patient_pco2_mean,
    ps.patient_lactate_mean,
    ps.patient_pao2fio2_mean,
    ps.patient_baseexcess_mean,
    ps.patient_bicarbonate_mean,
    ps.patient_fio2_mean,
    ps.patient_so2_mean,
    ps.patient_spo2_mean,
    ps.patient_glucose_mean,
    ps.patient_hematocrit_mean,
    ps.patient_hemoglobin_mean,
    ps.patient_potassium_mean,
    ps.patient_sodium_mean,
    ps.patient_chloride_mean,
    ps.patient_calcium_mean,
    ps.patient_temperature_mean,
    -- Forward fill (carry forward from previous time bin)
    LAG(ph_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_ph,
    LAG(po2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_po2,
    LAG(pco2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_pco2,
    LAG(lactate_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_lactate,
    LAG(pao2fio2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_pao2fio2,
    LAG(baseexcess_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_baseexcess,
    LAG(bicarbonate_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_bicarbonate,
    LAG(fio2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_fio2,
    LAG(so2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_so2,
    LAG(spo2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_spo2,
    LAG(glucose_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_glucose,
    LAG(hematocrit_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_hematocrit,
    LAG(hemoglobin_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_hemoglobin,
    LAG(potassium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_potassium,
    LAG(sodium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_sodium,
    LAG(chloride_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_chloride,
    LAG(calcium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_calcium,
    LAG(temperature_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS prev_temperature,
    -- Backward fill (carry backward from next time bin)
    LEAD(ph_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_ph,
    LEAD(po2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_po2,
    LEAD(pco2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_pco2,
    LEAD(lactate_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_lactate,
    LEAD(pao2fio2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_pao2fio2,
    LEAD(baseexcess_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_baseexcess,
    LEAD(bicarbonate_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_bicarbonate,
    LEAD(fio2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_fio2,
    LEAD(so2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_so2,
    LEAD(spo2_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_spo2,
    LEAD(glucose_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_glucose,
    LEAD(hematocrit_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_hematocrit,
    LEAD(hemoglobin_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_hemoglobin,
    LEAD(potassium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_potassium,
    LEAD(sodium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_sodium,
    LEAD(chloride_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_chloride,
    LEAD(calcium_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_calcium,
    LEAD(temperature_avg, 1) OVER (PARTITION BY ab.icustay_id ORDER BY ab.hour_offset) AS next_temperature
    
  FROM abg_binned ab
  LEFT JOIN patient_stats ps
    ON ab.subject_id = ps.subject_id
    AND ab.hadm_id = ps.hadm_id
    AND ab.icustay_id = ps.icustay_id
)
SELECT 
  fv.*,
  ps.pop_ph_mean,
  ps.pop_po2_mean,
  ps.pop_pco2_mean,
  ps.pop_lactate_mean,
  ps.pop_pao2fio2_mean,
  ps.pop_baseexcess_mean,
  ps.pop_bicarbonate_mean,
  ps.pop_fio2_mean,
  ps.pop_so2_mean,
  ps.pop_spo2_mean,
  ps.pop_glucose_mean,
  ps.pop_hematocrit_mean,
  ps.pop_hemoglobin_mean,
  ps.pop_potassium_mean,
  ps.pop_sodium_mean,
  ps.pop_chloride_mean,
  ps.pop_calcium_mean,
  ps.pop_temperature_mean,
  -- HIERARCHICAL IMPUTATION: measured → forward fill → backward fill → patient mean → population mean → normal values
  -- Core ABG parameters
  COALESCE(
    fv.ph_avg, fv.prev_ph, fv.next_ph, fv.patient_ph_mean, ps.pop_ph_mean, 7.40
  ) AS ph_imputed,
  
  COALESCE(
    fv.po2_avg, fv.prev_po2, fv.next_po2, fv.patient_po2_mean, ps.pop_po2_mean, 95
  ) AS po2_imputed,
  
  COALESCE(
    fv.pco2_avg, fv.prev_pco2, fv.next_pco2, fv.patient_pco2_mean, ps.pop_pco2_mean, 40
  ) AS pco2_imputed,
  
  COALESCE(
    fv.lactate_avg, fv.prev_lactate, fv.next_lactate, fv.patient_lactate_mean, ps.pop_lactate_mean, 1.5
  ) AS lactate_imputed,
  
  COALESCE(
    fv.pao2fio2_avg, fv.prev_pao2fio2, fv.next_pao2fio2, fv.patient_pao2fio2_mean, ps.pop_pao2fio2_mean, 400
  ) AS pao2fio2_imputed,
  
  COALESCE(
    fv.baseexcess_avg, fv.prev_baseexcess, fv.next_baseexcess, fv.patient_baseexcess_mean, ps.pop_baseexcess_mean, 0
  ) AS baseexcess_imputed,
  
  COALESCE(
    fv.bicarbonate_avg, fv.prev_bicarbonate, fv.next_bicarbonate, fv.patient_bicarbonate_mean, ps.pop_bicarbonate_mean, 24
  ) AS bicarbonate_imputed,
  
  COALESCE(
    fv.fio2_avg, fv.prev_fio2, fv.next_fio2, fv.patient_fio2_mean, ps.pop_fio2_mean, 21
  ) AS fio2_imputed,
  
  COALESCE(
    fv.so2_avg, fv.prev_so2, fv.next_so2, fv.patient_so2_mean, ps.pop_so2_mean, 97
  ) AS so2_imputed,
  
  COALESCE(
    fv.spo2_avg, fv.prev_spo2, fv.next_spo2, fv.patient_spo2_mean, ps.pop_spo2_mean, 97
  ) AS spo2_imputed,
  -- GLUCOSE IMPUTATION - FULLY INCLUDED
  COALESCE(
    fv.glucose_avg, fv.prev_glucose, fv.next_glucose, fv.patient_glucose_mean, ps.pop_glucose_mean, 100
  ) AS glucose_imputed,
  -- Lab values imputation
  COALESCE(
    fv.hematocrit_avg, fv.prev_hematocrit, fv.next_hematocrit, fv.patient_hematocrit_mean, ps.pop_hematocrit_mean, 40
  ) AS hematocrit_imputed,
  
  COALESCE(
    fv.hemoglobin_avg, fv.prev_hemoglobin, fv.next_hemoglobin, fv.patient_hemoglobin_mean, ps.pop_hemoglobin_mean, 12
  ) AS hemoglobin_imputed,
  
  COALESCE(
    fv.potassium_avg, fv.prev_potassium, fv.next_potassium, fv.patient_potassium_mean, ps.pop_potassium_mean, 4.0
  ) AS potassium_imputed,
  
  COALESCE(
    fv.sodium_avg, fv.prev_sodium, fv.next_sodium, fv.patient_sodium_mean, ps.pop_sodium_mean, 140
  ) AS sodium_imputed,
  
  COALESCE(
    fv.chloride_avg, fv.prev_chloride, fv.next_chloride, fv.patient_chloride_mean, ps.pop_chloride_mean, 102
  ) AS chloride_imputed,
  
  COALESCE(
    fv.calcium_avg, fv.prev_calcium, fv.next_calcium, fv.patient_calcium_mean, ps.pop_calcium_mean, 9.5
  ) AS calcium_imputed,
  
  COALESCE(
    fv.temperature_avg, fv.prev_temperature, fv.next_temperature, fv.patient_temperature_mean, ps.pop_temperature_mean, 37.0
  ) AS temperature_imputed,
  -- Imputation flags (1 = imputed, 0 = measured)
  CASE WHEN fv.ph_avg IS NULL THEN 1 ELSE 0 END AS ph_imputed_flag,
  CASE WHEN fv.po2_avg IS NULL THEN 1 ELSE 0 END AS po2_imputed_flag,
  CASE WHEN fv.pco2_avg IS NULL THEN 1 ELSE 0 END AS pco2_imputed_flag,
  CASE WHEN fv.lactate_avg IS NULL THEN 1 ELSE 0 END AS lactate_imputed_flag,
  CASE WHEN fv.pao2fio2_avg IS NULL THEN 1 ELSE 0 END AS pao2fio2_imputed_flag,
  CASE WHEN fv.baseexcess_avg IS NULL THEN 1 ELSE 0 END AS baseexcess_imputed_flag,
  CASE WHEN fv.bicarbonate_avg IS NULL THEN 1 ELSE 0 END AS bicarbonate_imputed_flag,
  CASE WHEN fv.glucose_avg IS NULL THEN 1 ELSE 0 END AS glucose_imputed_flag,
  CASE WHEN fv.hematocrit_avg IS NULL THEN 1 ELSE 0 END AS hematocrit_imputed_flag,
  CASE WHEN fv.hemoglobin_avg IS NULL THEN 1 ELSE 0 END AS hemoglobin_imputed_flag,
  CASE WHEN fv.potassium_avg IS NULL THEN 1 ELSE 0 END AS potassium_imputed_flag,
  CASE WHEN fv.sodium_avg IS NULL THEN 1 ELSE 0 END AS sodium_imputed_flag,
  -- Clinical severity flags based on imputed values
  CASE WHEN COALESCE(fv.ph_min, fv.ph_avg, fv.prev_ph, fv.next_ph, fv.patient_ph_mean, ps.pop_ph_mean, 7.40) < 7.30 THEN 1 ELSE 0 END AS severe_acidosis,
  CASE WHEN COALESCE(fv.ph_max, fv.ph_avg, fv.prev_ph, fv.next_ph, fv.patient_ph_mean, ps.pop_ph_mean, 7.40) > 7.50 THEN 1 ELSE 0 END AS severe_alkalosis,
  CASE WHEN COALESCE(fv.pao2fio2_min, fv.pao2fio2_avg, fv.prev_pao2fio2, fv.next_pao2fio2, fv.patient_pao2fio2_mean, ps.pop_pao2fio2_mean, 400) < 200 THEN 1 ELSE 0 END AS severe_hypoxemia,
  CASE WHEN COALESCE(fv.pao2fio2_min, fv.pao2fio2_avg, fv.prev_pao2fio2, fv.next_pao2fio2, fv.patient_pao2fio2_mean, ps.pop_pao2fio2_mean, 400) < 300 THEN 1 ELSE 0 END AS impaired_oxygenation,
  CASE WHEN COALESCE(fv.lactate_max, fv.lactate_avg, fv.prev_lactate, fv.next_lactate, fv.patient_lactate_mean, ps.pop_lactate_mean, 1.5) > 4.0 THEN 1 ELSE 0 END AS severe_hyperlactatemia,
  CASE WHEN COALESCE(fv.pco2_max, fv.pco2_avg, fv.prev_pco2, fv.next_pco2, fv.patient_pco2_mean, ps.pop_pco2_mean, 40) > 50 THEN 1 ELSE 0 END AS hypercapnia,
  CASE WHEN COALESCE(fv.pco2_min, fv.pco2_avg, fv.prev_pco2, fv.next_pco2, fv.patient_pco2_mean, ps.pop_pco2_mean, 40) < 35 THEN 1 ELSE 0 END AS hypocapnia,
  -- GLUCOSE CLINICAL FLAGS
  CASE WHEN COALESCE(fv.glucose_max, fv.glucose_avg, fv.prev_glucose, fv.next_glucose, fv.patient_glucose_mean, ps.pop_glucose_mean, 100) > 180 THEN 1 ELSE 0 END AS hyperglycemia,
  CASE WHEN COALESCE(fv.glucose_max, fv.glucose_avg, fv.prev_glucose, fv.next_glucose, fv.patient_glucose_mean, ps.pop_glucose_mean, 100) > 250 THEN 1 ELSE 0 END AS severe_hyperglycemia,
  CASE WHEN COALESCE(fv.glucose_min, fv.glucose_avg, fv.prev_glucose, fv.next_glucose, fv.patient_glucose_mean, ps.pop_glucose_mean, 100) < 70 THEN 1 ELSE 0 END AS hypoglycemia,
  CASE WHEN COALESCE(fv.glucose_min, fv.glucose_avg, fv.prev_glucose, fv.next_glucose, fv.patient_glucose_mean, ps.pop_glucose_mean, 100) < 50 THEN 1 ELSE 0 END AS severe_hypoglycemia,
  -- Additional clinical flags
  CASE WHEN COALESCE(fv.potassium_avg, fv.prev_potassium, fv.next_potassium, fv.patient_potassium_mean, ps.pop_potassium_mean, 4.0) > 5.5 THEN 1 ELSE 0 END AS hyperkalemia,
  CASE WHEN COALESCE(fv.potassium_avg, fv.prev_potassium, fv.next_potassium, fv.patient_potassium_mean, ps.pop_potassium_mean, 4.0) < 3.0 THEN 1 ELSE 0 END AS hypokalemia,
  CASE WHEN COALESCE(fv.sodium_avg, fv.prev_sodium, fv.next_sodium, fv.patient_sodium_mean, ps.pop_sodium_mean, 140) > 150 THEN 1 ELSE 0 END AS hypernatremia,
  CASE WHEN COALESCE(fv.sodium_avg, fv.prev_sodium, fv.next_sodium, fv.patient_sodium_mean, ps.pop_sodium_mean, 140) < 130 THEN 1 ELSE 0 END AS hyponatremia,
  -- Calculated imputed P/F ratio for cases where both components are imputed
  CASE 
    WHEN COALESCE(fv.po2_avg, fv.prev_po2, fv.next_po2, fv.patient_po2_mean, ps.pop_po2_mean, 95) IS NOT NULL 
    AND COALESCE(fv.fio2_avg, fv.prev_fio2, fv.next_fio2, fv.patient_fio2_mean, ps.pop_fio2_mean, 21) IS NOT NULL
    THEN 100 * COALESCE(fv.po2_avg, fv.prev_po2, fv.next_po2, fv.patient_po2_mean, ps.pop_po2_mean, 95) / 
              COALESCE(fv.fio2_avg, fv.prev_fio2, fv.next_fio2, fv.patient_fio2_mean, ps.pop_fio2_mean, 21)
    ELSE NULL 
  END AS pao2fio2_calculated_imputed

FROM filled_values fv
CROSS JOIN population_stats ps
ORDER BY fv.icustay_id, fv.hour_offset;

-- Add comprehensive indexes for performance
CREATE INDEX idx_abg_agg_icustay ON bloodGasArterial_4bin_agg(icustay_id);
CREATE INDEX idx_abg_agg_hour ON bloodGasArterial_4bin_agg(hour_offset);
CREATE INDEX idx_abg_agg_pf ON bloodGasArterial_4bin_agg(pao2fio2_imputed);
CREATE INDEX idx_abg_agg_glucose ON bloodGasArterial_4bin_agg(glucose_imputed);
CREATE INDEX idx_abg_agg_composite ON bloodGasArterial_4bin_agg(subject_id, hadm_id, icustay_id, hour_offset);
CREATE INDEX idx_abg_agg_severity ON bloodGasArterial_4bin_agg(severe_hypoxemia, severe_acidosis, severe_hyperlactatemia);
CREATE INDEX idx_abg_agg_glucose_flags ON bloodGasArterial_4bin_agg(hyperglycemia, severe_hyperglycemia, hypoglycemia);


select * from `bloodGasArterial_4bin_agg`;


-- Magnesium
ALTER TABLE bloodGasArterial_4bin_agg 
ADD COLUMN magnesium_min DECIMAL(4,2),
ADD COLUMN magnesium_max DECIMAL(4,2),
ADD COLUMN magnesium_avg DECIMAL(4,2),
ADD COLUMN magnesium_imputed DECIMAL(4,2);

UPDATE bloodGasArterial_4bin_agg bg
SET 
    magnesium_min = (
        SELECT MIN(le.valuenum)
        FROM labevents le
        WHERE le.subject_id = bg.subject_id
        AND le.hadm_id = bg.hadm_id
        AND le.itemid = 50960  -- Magnesium
        AND le.charttime >= bg.bin_start_time
        AND le.charttime < bg.bin_end_time
        AND le.valuenum IS NOT NULL
        AND le.valuenum > 0.5
        AND le.valuenum < 5.0  -- Reasonable filter for magnesium (mg/dL)
    ),
    magnesium_max = (
        SELECT MAX(le.valuenum)
        FROM labevents le
        WHERE le.subject_id = bg.subject_id
        AND le.hadm_id = bg.hadm_id
        AND le.itemid = 50960
        AND le.charttime >= bg.bin_start_time
        AND le.charttime < bg.bin_end_time
        AND le.valuenum IS NOT NULL
        AND le.valuenum > 0.5
        AND le.valuenum < 5.0
    ),
    magnesium_avg = (
        SELECT AVG(le.valuenum)
        FROM labevents le
        WHERE le.subject_id = bg.subject_id
        AND le.hadm_id = bg.hadm_id
        AND le.itemid = 50960
        AND le.charttime >= bg.bin_start_time
        AND le.charttime < bg.bin_end_time
        AND le.valuenum IS NOT NULL
        AND le.valuenum > 0.5
        AND le.valuenum < 5.0
    );

DROP TEMPORARY TABLE IF EXISTS magnesium_patient_stats;
CREATE TEMPORARY TABLE magnesium_patient_stats AS
SELECT 
    subject_id,
    hadm_id,
    icustay_id,
    AVG(magnesium_avg) AS patient_magnesium_mean
FROM bloodGasArterial_4bin_agg
WHERE magnesium_avg IS NOT NULL
GROUP BY subject_id, hadm_id, icustay_id;

DROP TEMPORARY TABLE IF EXISTS magnesium_population_stats;
CREATE TEMPORARY TABLE magnesium_population_stats AS
SELECT 
    AVG(magnesium_avg) AS pop_magnesium_mean
FROM bloodGasArterial_4bin_agg
WHERE magnesium_avg IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS magnesium_filled;
CREATE TEMPORARY TABLE magnesium_filled AS
SELECT 
    bg.subject_id,
    bg.hadm_id,
    bg.icustay_id,
    bg.hour_offset,
    bg.magnesium_avg,
    -- Forward fill (carry last observation forward)
    LAG(bg.magnesium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_magnesium,
    LAG(bg.magnesium_avg, 2) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_magnesium_2,
    LAG(bg.magnesium_avg, 3) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS prev_magnesium_3,
    -- Backward fill (next observation carried backward)
    LEAD(bg.magnesium_avg, 1) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_magnesium,
    LEAD(bg.magnesium_avg, 2) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_magnesium_2,
    LEAD(bg.magnesium_avg, 3) OVER (PARTITION BY bg.icustay_id ORDER BY bg.hour_offset) AS next_magnesium_3,
    -- Patient mean
    ps.patient_magnesium_mean,
    -- Population mean
    pop.pop_magnesium_mean
FROM bloodGasArterial_4bin_agg bg
LEFT JOIN magnesium_patient_stats ps
    ON bg.subject_id = ps.subject_id
    AND bg.hadm_id = ps.hadm_id
    AND bg.icustay_id = ps.icustay_id
CROSS JOIN magnesium_population_stats pop;


UPDATE bloodGasArterial_4bin_agg bg
JOIN magnesium_filled mf
    ON bg.subject_id = mf.subject_id
    AND bg.hadm_id = mf.hadm_id
    AND bg.icustay_id = mf.icustay_id
    AND bg.hour_offset = mf.hour_offset
SET bg.magnesium_imputed = 
    COALESCE(
        -- 1. Original measured value
        mf.magnesium_avg,
        -- 2. Forward fill (1-3 time bins back)
        mf.prev_magnesium,
        mf.prev_magnesium_2,
        mf.prev_magnesium_3,
        -- 3. Backward fill (1-3 time bins forward)
        mf.next_magnesium,
        mf.next_magnesium_2,
        mf.next_magnesium_3,
        -- 4. Patient-specific mean
        mf.patient_magnesium_mean,
        -- 5. Population mean
        mf.pop_magnesium_mean,
        -- 6. Clinical normal value (mid-range normal)
        1.9  -- Normal Mg: 1.7-2.2 mg/dL, using 1.9 as default
    );

ALTER TABLE bloodGasArterial_4bin_agg 
ADD COLUMN magnesium_imputed_flag TINYINT(1) DEFAULT 0;

UPDATE bloodGasArterial_4bin_agg 
SET magnesium_imputed_flag = CASE WHEN magnesium_avg IS NULL THEN 1 ELSE 0 END;


SELECT AVG(magnesium_imputed) FROM `bloodGasArterial_4bin_agg`;