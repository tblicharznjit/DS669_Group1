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

select count(DISTINCT icustay_id) from final_dataset;

SELECT COUNT(DISTINCT(subject_id)) FROM final_dataset;

SELECT COUNT(DISTINCT(subject_id)) FROM final_dataset WHERE `Gender`=1;

SELECT COUNT(DISTINCT(subject_id)) FROM final_dataset WHERE `Death`=1;

SELECT 
    -- Patient Demographics (averages and std dev)
    AVG(Age) as avg_age,
    STDDEV(Age) as std_age,
    AVG(Weight) as avg_weight,
    STDDEV(Weight) as std_weight,
    -- Blood Gas Parameters
    AVG(PH) as avg_ph,
    STDDEV(PH) as std_ph,
    AVG(PaO2) as avg_pao2,
    STDDEV(PaO2) as std_pao2,
    AVG(PaCO2) as avg_paco2,
    STDDEV(PaCO2) as std_paco2,
    AVG(`PaO2/FiO2`) as avg_pao2_fio2,
    STDDEV(`PaO2/FiO2`) as std_pao2_fio2,
    AVG(ArterialBE) as avg_arterial_be,
    STDDEV(ArterialBE) as std_arterial_be,
    AVG(HCO3) as avg_hco3,
    STDDEV(HCO3) as std_hco3,
    AVG(FiO2) as avg_fio2,
    STDDEV(FiO2) as std_fio2,
    AVG(HGB) as avg_hemoglobin,
    STDDEV(HGB) as std_hemoglobin,
    AVG(Chloride) as avg_chloride,
    STDDEV(Chloride) as std_chloride,
    AVG(Calcium) as avg_calcium,
    STDDEV(Calcium) as std_calcium,
    AVG(Magnesium) as avg_magnesium,
    STDDEV(Magnesium) as std_magnesium,
    AVG(SGPT) as avg_sgpt,
    STDDEV(SGPT) as std_sgpt,
    AVG(SGOT) as avg_sgot,
    STDDEV(SGOT) as std_sgot,
    -- Vital Signs
    AVG(Temperature) as avg_temperature,
    STDDEV(Temperature) as std_temperature,
    AVG(HR) as avg_heart_rate,
    STDDEV(HR) as std_heart_rate,
    AVG(RR) as avg_resp_rate,
    STDDEV(RR) as std_resp_rate,
    AVG(SBP) as avg_systolic_bp,
    STDDEV(SBP) as std_systolic_bp,
    AVG(DBP) as avg_diastolic_bp,
    STDDEV(DBP) as std_diastolic_bp,
    AVG(MBP) as avg_mean_bp,
    STDDEV(MBP) as std_mean_bp,
    AVG(ShockIndex) as avg_shock_index,
    STDDEV(ShockIndex) as std_shock_index,
    AVG(SpO2) as avg_spo2,
    STDDEV(SpO2) as std_spo2,
    -- Lab Values
    AVG(AL) as avg_lactate,
    STDDEV(AL) as std_lactate,
    AVG(BUN) as avg_bun,
    STDDEV(BUN) as std_bun,
    AVG(Creatinine) as avg_creatinine,
    STDDEV(Creatinine) as std_creatinine,
    AVG(Platelet) as avg_platelet,
    STDDEV(Platelet) as std_platelet,
    AVG(WBC) as avg_wbc,
    STDDEV(WBC) as std_wbc,
    AVG(Potassium) as avg_potassium,
    STDDEV(Potassium) as std_potassium,
    AVG(Sodium) as avg_sodium,
    STDDEV(Sodium) as std_sodium,
    AVG(Glucose) as avg_glucose,
    STDDEV(Glucose) as std_glucose,
    AVG(PTT) as avg_ptt,
    STDDEV(PTT) as std_ptt,
    AVG(PT) as avg_pt,
    STDDEV(PT) as std_pt,
    AVG(INR) as avg_inr,
    STDDEV(INR) as std_inr,
    AVG(TB) as avg_total_bilirubin,
    STDDEV(TB) as std_total_bilirubin,
    -- Fluid Balance
    AVG(CB) as avg_cumulative_balance,
    STDDEV(CB) as std_cumulative_balance,
    AVG(TotalInput) as avg_total_input,
    STDDEV(TotalInput) as std_total_input,
    AVG(TotalOutput) as avg_total_output,
    STDDEV(TotalOutput) as std_total_output,
    AVG(`4hourlyOutput`) as avg_4hourly_output,
    STDDEV(`4hourlyOutput`) as std_4hourly_output,
    -- Scores
    AVG(SOFA) as avg_sofa,
    STDDEV(SOFA) as std_sofa,
    AVG(SIRS) as avg_sirs,
    STDDEV(SIRS) as std_sirs,
    AVG(GCS) as avg_gcs,
    STDDEV(GCS) as std_gcs
    
FROM final_dataset;