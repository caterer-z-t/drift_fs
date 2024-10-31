# In[1]: Import Libraries
import pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
plt.style.use('ggplot')
from matplotlib_venn import venn2, venn3
from itertools import combinations
from tqdm import tqdm
from pycaret.regression import *
import os
import time
import shutil

from utils.utils import prepare_baseline_data, merge_dataframes, keep_columns
from utils.anova import Run_ANOVA
from utils.etc import Run_ETC
from utils.rfe import Run_RFE
from utils.rf import run_rf
from utils.lasso import Run_Lasso

# In[2]: Load Data

# Get the directory of the current script and append the relative path to stanislawski_lab_data
base_file_path = (Path(__file__).parent / "../stanislawski_lab_data").resolve()

# Load Data
drift_metadata = pd.read_csv(base_file_path / "DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv")
merge_meta_df = pd.read_csv(base_file_path / "merge_meta_methyl.csv")
genus_clr_df = pd.read_csv(base_file_path / "genus.clr.csv")

# removing these datasets becuase the count df and ra df are just transformations to aquire the clr df
genus_count_df = pd.read_csv(base_file_path / "genus.count.csv")
genus_ra_df = pd.read_csv(base_file_path / "genus.ra.csv")

# removing the specices df because we want to focus on the analysis of the genus data for now, could include this later
sp_clr_df = pd.read_csv(base_file_path / "sp.clr.csv")
sp_count_df = pd.read_csv(base_file_path / "sp.count.csv")
sp_ra_df = pd.read_csv(base_file_path / "sp.ra.csv")

genus_df_list = [
    genus_clr_df,
    genus_count_df,
    genus_ra_df
    ]
sp_df_list = [sp_clr_df, sp_count_df, sp_ra_df]

taxa_dict = {
    "genus": genus_df_list,
    "species": sp_df_list
}

# In[3]: Data Preprocessing

# remove row if conset was no
merge_meta_df = merge_meta_df[merge_meta_df['consent'] == 'yes']

# remove columns
remove_columns = ['3m', '6m', '12m', '18m',
                              'PC', 'pc', 'bug', 'array', 'sex.y', 'age.y',
                              'cohort', 'race.y', 'ethnicity.y', 'timepoint', 'duplicate_sample', 
                              'SampleID', 'outcome_bmi_current', 'sample_name', 'sentrix', 'mrs.wt', 'mrs.std.wt', 'start_treatment', 
                              'withdrawal_date_check']

# columns to use
columns = [
    'subject_id',
    'gender',      # what are these values, they are currently binary 
    'age.x', 
    'race.x',       # what are these values, they are numerical before preprocessing?
    # 'race_fact',   # these are the same but these values are categorical
    'ethnicity.x', # what are these values, they are numerical before preprocessing?
    'education',   # what are these values, they are numerical before preprocessing?
    # 'job_activity',   # what are these values, they are numerical before preprocessing?
    # 'income',         # what are these values, they are numerical before preprocessing?
    # 'marital_status', # what are these values, they are numerical before preprocessing?
    "height_inches",
    'rmr_kcald_BL',
    'spk_EE_int_kcal_day_BL',
    'avg_systolic_BL',
    'avg_diastolic_BL',
    'C_Reactive_Protein_BL',
    'Cholesterol_lipid_BL',
    'Ghrelin_BL',
    'Glucose_BL',
    'HDL_Total_Direct_lipid_BL',
    'Hemoglobin_A1C_BL',
    'Insulin_endo_BL',
    'LDL_Calculated_BL',
    'Leptin_BL',
    'Peptide_YY_BL',
    'Triglyceride_lipid_BL',
    'HOMA_IR_BL',
    'differences_BL_BMI'
    ]

merge_meta_df = keep_columns(merge_meta_df, columns)

for taxa, taxa_df_list in taxa_dict.items():
    for idx, df in enumerate(taxa_df_list):
        data = merge_dataframes(df, merge_meta_df)

        # overwrite the taxa_df_list with the new data
        taxa_df_list[idx] = data

# In[4]: Feature Selection (Previous Methods) Wrtiting scripts to make sure they work
# our X data is each of the taxa dataframes
# our y data is the merge_meta_df['differences_BL_BMI']
# merge_meta_df['differences_BL_BMI'] is the target variable
# Initialize an empty dictionary to store the feature selection results
feature_selection_results = {}

# Use tqdm to track the progress of taxa iteration
for taxa, taxa_df_list in tqdm(taxa_dict.items(), desc="Taxa Progress", unit="taxa"):

    feature_selection_results[taxa] = {}  # Create a new key for each taxa
    
    # Use tqdm to track the progress of dataset iteration
    for idx, df in enumerate(tqdm(taxa_df_list, desc=f"{taxa} Datasets", unit="dataset", leave=False)):

        # Define the name for each dataset in a readable format (optional)
        dataset_names = ['clr', 'count', 'ra']  # Assuming three datasets in the list
        dataset_name = f"{taxa}_{dataset_names[idx]}"
        
        # Create a dictionary for this specific dataset
        feature_selection_results[taxa][dataset_name] = {}
        
        y = df['differences_BL_BMI']
        df = df.drop(columns=['differences_BL_BMI'])
        X = df.drop(columns=['subject_id']).dropna(axis=1)

        # Set the number of top features you want to select
        n_to_select = 100  # Adjust as needed
        seed = 42  

        # Use tqdm to track the progress of feature selection methods
        for method_name, func in tqdm([
                ('Random Forest', run_rf),
                ('Extra Trees', Run_ETC),
                ('RFE', Run_RFE),
                ('ANOVA', Run_ANOVA),
                ('Lasso', Run_Lasso)
            ], desc=f"{dataset_name} Feature Selection", unit="method", leave=False):
            
            if method_name == 'Random Forest':
                top_features, model = func(n_to_select, X, y, test_size=0.3, random_state=seed)

            elif method_name == 'Extra Trees':
                top_features, model = func(n_to_select, X, y, seed_value=seed)

            elif method_name == 'RFE':
                top_features, model = func(n_to_select, X, y, flip=False)

            elif method_name == 'ANOVA':
                top_features, model = func(n_to_select, X, y, flip=True)

            elif method_name == 'Lasso':
                top_features, model = func(n_to_select, X, y, flip=True, seed=seed)

            # Store the top features for each method
            feature_selection_results[taxa][dataset_name][method_name] = top_features

            # Store the time taken for each method
            # feature_selection_results[taxa][dataset_name][f"{method_name}_time"] = {
            #     'Random Forest': rf_time,
            #     'Extra Trees': et_time,
            #     'RFE': rfe_time,
            #     'ANOVA': anova_time,
            #     'Lasso': lasso_time
            # }

        # Plotting Venn Diagrams
        # Extract top features for each method
        feature_sets = {method_name: set(top_features) for method_name, top_features in feature_selection_results[taxa][dataset_name].items()}

        # Create a figure with subplots
        fig, axes = plt.subplots(5, 4, figsize=(20, 25))  # Adjust size as needed
        axes = axes.flatten()

        # Pairwise Venn Diagrams
        pairwise_combos = list(combinations(feature_sets.keys(), 2))
        for i, (set1, set2) in enumerate(pairwise_combos):
            venn2([feature_sets[set1], feature_sets[set2]], set_labels=(set1, set2), ax=axes[i])

        # Triple Venn Diagrams
        triple_combos = list(combinations(feature_sets.keys(), 3))
        for i, (set1, set2, set3) in enumerate(triple_combos, len(pairwise_combos)):
            venn3([feature_sets[set1], feature_sets[set2], feature_sets[set3]], set_labels=(set1, set2, set3), ax=axes[i])

        # Adjust layout
        plt.tight_layout()
        plt.suptitle(f'Feature Selection Comparison for {dataset_name}', fontsize=16)  # Title for the dataset
        plt.subplots_adjust(top=0.95)  # Adjust for the title

        # Save the figure
        plt.savefig(f'figures/venn_diagram_{dataset_name}.png')  # Save with dataset name
        # plt.show()  # Show the plot


# In[5]: Using pycaret for feature selection

for taxa, taxa_df_list in taxa_dict.items():
    for idx, df in enumerate(taxa_df_list):
        # running pycaret analysis on dataset with latent information
        latent_setup = setup(df,
                      target = 'differences_BL_BMI',
                      session_id = 123, 
                      # feature_selection = True,
                      # fold = 5, # default is 10
                      # preprocess = False, 
                      # imputation_type = 'iterative',
                      # normalize = True,
        )
        # comparing all models
        best_model = compare_models()
        plot_model(best_model, plot = 'feature', save = True)

        # wait for the plot to save
        wait_time = 5
        print(f"Waiting for {wait_time} seconds for the plot to save")
        time.sleep(wait_time)

        # move the saved plot to the figures folder
        shutil.move("Feature Importance.png", f"figures/feature_selection_{taxa}_{idx}_latent.png")

        # now run same analysis without latent information
        for col in df.columns:
            contains_underscore = [col for col in df.columns if '__' in col]
        contains_underscore.append('differences_BL_BMI')
        df = df[contains_underscore]

        # running pycaret analysis on dataset with latent information
        no_latent_setup = setup(df,
                      target = 'differences_BL_BMI',
                      session_id = 123, 
                      # feature_selection = True,
                      # fold = 5, # default is 10
                      # preprocess = False, 
                      # imputation_type = 'iterative',
                      # normalize = True,
        )
        # comparing all models
        best_model = compare_models()
        plot_model(best_model, plot = 'feature', save = True)

        # wait for the plot to save
        wait_time = 5
        print(f"Waiting for {wait_time} seconds for the plot to save")
        time.sleep(wait_time)

        # move the saved plot to the figures folder
        shutil.move("Feature Importance.png", f"figures/feature_selection_{taxa}_{idx}.png")


