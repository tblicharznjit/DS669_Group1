import pandas as pd
import numpy as np
import pickle
from tqdm import tqdm

# =============== CONFIG ===============
data_path = "C:/Users/BeastfrmHell/Desktop/mimic-iii-clinical-database-1.4"

output_file = "患者总数据.pkl"

# =============== LOAD DATA ===============
print("Loading CSVs...")
adm = pd.read_csv(f"{data_path}/ADMISSIONS.csv")
icu = pd.read_csv(f"{data_path}/ICUSTAYS.csv")
patients = pd.read_csv(f"{data_path}/PATIENTS.csv")
chartevents = pd.read_csv(f"{data_path}/CHARTEVENTS.csv", nrows=1000000)  # limit for testing
print(chartevents['ITEMID'].unique())


labevents = pd.read_csv(f"{data_path}/LABEVENTS.csv", nrows=500000)  # limit for testing
inputevents = pd.read_csv(f"{data_path}/INPUTEVENTS_MV.csv", nrows=500000)

# =============== EXTRACT FEATURES ===============
print("Processing features...")
# Example: Use heart rate (HR) and mean arterial pressure (MAP) for demonstration
# In practice, expand to the 37 features needed

features = {
    'HeartRate': [220045],    # Metavision ITEMID for HR
    'MeanBP': [220181]        # Metavision ITEMID for MAP
}

df_list = []
for feat_name, itemids in features.items():
    df = chartevents[chartevents['ITEMID'].isin(itemids)][['SUBJECT_ID', 'ICUSTAY_ID', 'CHARTTIME', 'VALUENUM']]
    df = df.rename(columns={'VALUENUM': feat_name})
    df_list.append(df)

# Ensure CHARTTIME is in datetime format for merge_asof
for df in df_list:
    df['CHARTTIME'] = pd.to_datetime(df['CHARTTIME'])


print("Merging features...")
df_merged = df_list[0]
for df in df_list[1:]:
    df_merged = pd.merge_asof(df_merged.sort_values('CHARTTIME'),
                               df.sort_values('CHARTTIME'),
                               on='CHARTTIME',
                               by=['SUBJECT_ID', 'ICUSTAY_ID'],
                               direction='nearest')

# =============== DUMMY ACTIONS AND REWARDS ===============
n_samples = len(df_merged)
X = df_merged[['HeartRate', 'MeanBP']].fillna(0).to_numpy()
Xnext = np.roll(X, -1, axis=0)
Action = np.random.randint(0, 25, n_samples)
ActionNext = np.roll(Action, -1)
Reward = np.random.randn(n_samples)
Done = np.zeros(n_samples)
Done[-1] = 1
Bloc = np.arange(n_samples)
SOFA = np.random.randint(0, 20, n_samples)

# =============== PACKAGE DATA ===============
MIMICtable = {
    'X': X,
    'Xnext': Xnext,
    'Action': Action,
    'ActionNext': ActionNext,
    'Reward': Reward,
    'Done': Done,
    'Bloc': Bloc,
    'SOFA': SOFA
}

# =============== SAVE ===============
with open(output_file, 'wb') as f:
    pickle.dump(MIMICtable, f)

print(f"✅ Saved {output_file} with {n_samples} samples ready for WD3QNE training.")

