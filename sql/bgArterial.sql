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