DROP TABLE IF EXISTS final_dataset;
CREATE TABLE final_dataset AS
SELECT
d.hadm_id,
d.icustay_id,
d.subject_id,
d.age as Age,
d.death as Death,
d.gender as Gender,
d.race_asian,
d.race_black,
d.race_latino,
d.race_white,
d.race_other,
d.mortality_90day as 90D_Mortality,
d.weight as Weight,
d.hour_offset as bin,
bg.ph_imputed as PH,
bg.po2_imputed as PaO2,
bg.pco2_imputed as PaCO2,
bg.pao2fio2_imputed as `PaO2/FiO2`,
bg.baseexcess_imputed as ArterialBE,
bg.bicarbonate_imputed as HCO3,
(bg.fio2_imputed)/100 as FiO2,
bg.hemoglobin_imputed as HGB,
bg.chloride_imputed as Chloride,
bg.calcium_imputed as Calcium,
bg.magnesium_imputed as Magnesium,
bg.sgpt_imputed as SGPT,
bg.sgot_imputed as SGOT,
v.tempc as Temperature,
v.heartrate as HR,
v.resprate as RR,
v.sysbp as SBP,
v.diasbp as DBP,
v.meanbp as MBP,
v.shock_index as ShockIndex,
v.spo2 as SpO2,
l.lactate_avg as AL,
l.bun_avg as BUN,
l.creatinine_avg as Creatinine,
l.platelet_avg as Platelet,
l.wbc_avg as WBC,
l.potassium_avg as Potassium,
l.sodium_avg as Sodium,
(l.glucose_avg)/18.016 as Glucose,
l.ptt_avg as PTT,
l.pt_avg as PT,
l.inr_avg as INR,
bi.total_bilirubin_imputed as TB,
fb.cumulative_balance as CB,
fb.total_input_cumulative as TotalInput,
fb.total_output_cumulative as TotalOutput,
fb.hourly_output_4hr as 4hourlyOutput,
sf.`SOFA` as SOFA,
si.sirs as SIRS,
gcs.avg_gcs as GCS
FROM `demographics_imputed` d
JOIN `4hr_time_bins` b
ON d.subject_id = b.subject_id AND d.hadm_id = b.hadm_id AND d.icustay_id = b.icustay_id AND d.hour_offset = b.hour_offset
LEFT JOIN `bloodGasArterial_4bin_imputed` bg ON bg.subject_id = b.subject_id AND bg.hadm_id = b.hadm_id AND bg.icustay_id = b.icustay_id AND bg.hour_offset = b.hour_offset
LEFT JOIN `vitals_4bin_imputed` v ON v.subject_id = b.subject_id AND v.hadm_id = b.hadm_id AND v.icustay_id = b.icustay_id AND v.hour_offset = b.hour_offset
LEFT JOIN `labVals_4bin_imputed` l ON l.subject_id = b.subject_id AND l.hadm_id = b.hadm_id AND l.icustay_id = b.icustay_id AND l.hour_offset = b.hour_offset
LEFT JOIN `bilirubin_4bin_imputed` bi ON bi.subject_id = b.subject_id AND bi.hadm_id = b.hadm_id AND bi.icustay_id = b.icustay_id AND bi.hour_offset = b.hour_offset
LEFT JOIN `fluidBalance_complete_4bin_agg` fb ON fb.subject_id = b.subject_id AND fb.hadm_id = b.hadm_id AND fb.icustay_id = b.icustay_id AND fb.hour_offset = b.hour_offset
LEFT JOIN `sofa_table_4bin` sf ON sf.subject_id = b.subject_id AND sf.hadm_id = b.hadm_id AND sf.icustay_id = b.icustay_id AND sf.hour_offset = b.hour_offset
LEFT JOIN `sirs_4bin` si ON si.subject_id = b.subject_id AND si.hadm_id = b.hadm_id AND si.icustay_id = b.icustay_id AND si.hour_offset = b.hour_offset
LEFT JOIN `gcs_4bin_imputed` gcs ON gcs.subject_id = b.subject_id AND gcs.hadm_id = b.hadm_id AND gcs.icustay_id = b.icustay_id AND gcs.hour_offset = b.hour_offset;


select * from final_dataset;