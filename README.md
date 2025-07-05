Ensure these two are downloaded:
  ID3QNE-aglorithm-main Link: https://github.com/CaryLi666/ID3QNE-algorithm
  Mimic-iii-clinical-database-1.4 

Add the two files into the ID3QNE-aglorithm-main.
Follow the instructions I left under the two files
  Here's a copy of those same instructions
      Follow the following steps:
      1. Open generate_patient_pkl.py
      2. Edit Line 7 Data_Path: input your location of Mimic-iii-clinical-database-1.4
      3. Run python generate_patient_pkl.py inside Terminal ( I used PyCharm, you could use whatever you're comfortable with)
      4. This will generate the "患者总数据.pkl" for our WD3QNE training.
      5. Once that is generated, run python train_runner.py in Terminal
      6. WD3QNE Real Data Training is completed, and it should save it to folder.
