# In[1]: Import Libraries
import pandas as pd
import matplotlib.pyplot as plt
plt.style.use('ggplot')
from matplotlib_venn import venn2, venn3
from itertools import combinations
from tqdm import tqdm
import time
# import pycaret 

from utils.utils import prepare_baseline_data
from utils.anova import Run_ANOVA
from utils.etc import Run_ETC
from utils.rfe import Run_RFE
from utils.rf import run_rf
from utils.lasso import Run_Lasso

# In[2]: Load Data
base_file_path = "/home/zaca2954/iq_bio/stanislawski_lab/stanislawski_lab_data/"

# drift_metadata = pd.read_csv(base_file_path + "DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv")
merge_meta_df = pd.read_csv(base_file_path + "merge_meta_methyl.csv") # is the merged dataset with the drift information

genus_clr_df = pd.read_csv(base_file_path + "genus.clr.csv")

# removing these datasets becuase the count df and ra df are just transformations to aquire the clr df
# genus_count_df = pd.read_csv(base_file_path + "genus.count.csv")
# genus_ra_df = pd.read_csv(base_file_path + "genus.ra.csv")

# removing the specices df because we want to focus on the analysis of the genus data for now, could include this later
# sp_clr_df = pd.read_csv(base_file_path + "sp.clr.csv")
# sp_count_df = pd.read_csv(base_file_path + "sp.count.csv")
# sp_ra_df = pd.read_csv(base_file_path + "sp.ra.csv")

genus_df_list = [
    genus_clr_df,
    # genus_count_df,
    # genus_ra_df
    ]
# sp_df_list = [sp_clr_df, sp_count_df, sp_ra_df]

taxa_dict = {
    "genus": genus_df_list,
    # "species": sp_df_list
}

# In[3]: Data Preprocessing
# remove all the columns containing ['3m', '6m', '12m', '18m']
# this is because this is the timeseries data and for right now
# we only have the baseline data
for col in merge_meta_df.columns:
    if any(x in col for x in ['3m', '6m', '12m', '18m',
                              'PC', 'pc', 'bug', 'array', 'sex.y', 'age.y',
                              'cohort', 'race.y', 'ethnicity.y', 'timepoint', 'duplicate_sample', 
                              'SampleID', 'outcome_bmi_current', 'sample_name', 'sentrix', 'mrs.wt', 'mrs.std.wt', 'start_treatment', 
                              'withdrawal_date_check']): # have I removed anything I shouldn't have?
        merge_meta_df = merge_meta_df.drop(columns=[col])

# TODO: Include code here to add metadata columns to the dataframes
# which could be potiential predictors for the model

# TODO: Normalize the data

for taxa, taxa_df_list in taxa_dict.items():

    for idx, df in enumerate(taxa_df_list):

        baseline_data = prepare_baseline_data(df)
        taxa_dict[taxa][idx] = baseline_data

        # include code here to remove the unconsenting paitents
        # remove this code if we want to include the unconsenting patients
        # consenting_patients = baseline_data['consent'] == 1
        # taxa_dict[taxa][idx] = baseline_data[consenting_patients]
        # print(f"Taxa: {taxa}, Dataset: {idx}, Shape: {baseline_data.shape}")

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
        
        y = merge_meta_df['differences_BL_BMI']
        X = df.iloc[:, 1:]  # Assuming you want to exclude the first column (subjectid)

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
                rf_start = time.time()
                top_features, model = func(n_to_select, X, y, test_size=0.3, random_state=seed)
                rf_end = time.time()
                rf_time = rf_end - rf_start

            elif method_name == 'Extra Trees':
                et_start = time.time()
                top_features, model = func(n_to_select, X, y, seed_value=seed)
                et_end = time.time()
                et_time = et_end - et_start

            elif method_name == 'RFE':
                rfe_start = time.time()
                top_features, model = func(n_to_select, X, y, flip=False)
                rfe_end = time.time()
                rfe_time = rfe_end - rfe_start

            elif method_name == 'ANOVA':
                anova_start = time.time()
                top_features, model = func(n_to_select, X, y, flip=True)
                anova_end = time.time()
                anova_time = anova_end - anova_start

            elif method_name == 'Lasso':
                lasso_start = time.time()
                top_features, model = func(n_to_select, X, y, flip=True, seed=seed)
                lasso_end = time.time()
                lasso_time = lasso_end - lasso_start

            # Store the top features for each method
            feature_selection_results[taxa][dataset_name][method_name] = top_features

            # Store the time taken for each method
            feature_selection_results[taxa][dataset_name][f"{method_name}_time"] = {
                'Random Forest': rf_time,
                'Extra Trees': et_time,
                'RFE': rfe_time,
                'ANOVA': anova_time,
                'Lasso': lasso_time
            }

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
