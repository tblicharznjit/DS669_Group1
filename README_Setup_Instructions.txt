1. Setup - Make sure you have all the following files listed below
   * analyze_dataset.py
   * ID3QNE_deepQnet.py
   * train_runner_multi.py   # runs all 4 experiments × 100 epochs
   * analyze_agent_policy_combined.py
   * finalData.csv           # Our data
   * requirements.txt 
2. Set up the environment
   * This was done on MacOS, Windows will vary
      1. cd ~/DS669_Group1        # or the folder where this repo lives
      2. python3 -m venv venv
      3. source venv/bin/activate
      4. # install dependencies
         1. pip install -r requirements.txt
         2. pip install matplotlib pandas numpy scikit-learn torch tqdm
3. Prepare Dataset
   * This does the following:
      1. Loads finalData.csv
      2. Uses 90D_Mortality as the label (1=death, 0=alive).
      3. Normalizes features (fit on train only).
      4. Creates a 25‑action space (5 fluid bins × 5 vasopressor bins; historical vaso set to 0 since the CSV has no vaso column).
      5. Creates train/val/test splits and saves requiredFile.pkl
   * RUN: 
      1. python3 analyze_dataset.py
   * OUTPUT:
      1. Saved requiredFile.pkl with 25-action space (vaso_bin=0 historically) and normalized splits.
4. Run all Experiments
   * This does the following
      1. This launches 4 runs at 100 epochs each:
   * RUN:
      1. caffeinate python3 train_runner_multi.py # keeps Mac awake during long runs
   * Outputs go to runs/<exp_name>/:
      1. <exp>_model.pt
      2. <exp>_training_log.txt
      3. <exp>_training_loss.png
      4. <exp>_train_action_distribution.png
      5. <exp>_train_survival_by_action.png
      6. <exp>_policy_combined.png (fluid, vaso, 3D heatmap — proportions)
      7. Plus a combined table: runs/summary_metrics.csv
   * Open a plot on macOS:


      8. open runs/exp1_baseline/exp1_baseline_policy_combined.png
      9. open runs/summary_metrics.csv