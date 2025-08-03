USE mimiciii4;
CREATE TABLE urineOutput_1 AS
WITH urine_output AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    SUM(
      CASE
        WHEN oe.itemid = 227488 AND oe.value > 0 THEN -1 * oe.value
        ELSE oe.value
      END
    ) AS urineoutput
  FROM cohort sc
  JOIN icustays ie
    ON sc.subject_id = ie.subject_id
    AND sc.hadm_id = ie.hadm_id
    AND sc.icustay_id = ie.icustay_id
    AND sc.earliestOnset BETWEEN ie.intime AND ie.outtime
  LEFT JOIN outputevents oe
    ON ie.subject_id = oe.subject_id
    AND ie.hadm_id = oe.hadm_id
    AND ie.icustay_id = oe.icustay_id
    AND oe.charttime BETWEEN sc.earliestOnset AND DATE_ADD(sc.earliestOnset, INTERVAL 24 HOUR)
  WHERE oe.itemid IN (
    -- CareVue urine output itemids
    40055, 43175, 40069, 40094, 40715, 40473, 40085, 40057, 40056, 40405, 40428, 40086, 40096, 40651,
    -- MetaVision urine output itemids
    226559, 226560, 226561, 226584, 226563, 226565, 226567, 226557, 226558, 227488, 227489
  )
  GROUP BY sc.subject_id, sc.hadm_id, sc.icustay_id, sc.earliestOnset
),
urine_output_final AS (
  SELECT 
    sc.subject_id,
    sc.hadm_id,
    sc.icustay_id,
    sc.earliestOnset,
    COALESCE(uo.urineoutput, 0) AS urineoutput
  FROM cohort sc
  LEFT JOIN urine_output uo
    ON sc.subject_id = uo.subject_id
    AND sc.hadm_id = uo.hadm_id
    AND sc.icustay_id = uo.icustay_id
)
SELECT 
  subject_id,
  hadm_id,
  icustay_id,
  earliestOnset,
  urineoutput
FROM urine_output_final
ORDER BY subject_id, hadm_id, icustay_id;