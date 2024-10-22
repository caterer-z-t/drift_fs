# In[1]:
########################################
###
###             Imports
###
########################################

import pandas as pd
import matplotlib.pyplot as plt
plt.style.use('ggplot')
from matplotlib_venn import venn2, venn3
from itertools import combinations

from utils.utils import prepare_baseline_data
from utils.anova import Run_ANOVA
from utils.etc import Run_ETC
from utils.rfe import Run_RFE
from utils.rf import run_rf
from utils.lasso import Run_Lasso

# In[2]:
########################################
###
###             Load Data
###
########################################

base_file_path = "/home/zaca2954/iq_bio/stanislawski_lab/stanislawski_lab_data/"

# drift_metadata = pd.read_csv(base_file_path + "DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv")
merge_meta_df = pd.read_csv(base_file_path + "merge_meta_methyl.csv") # is the merged dataset with the drift information

genus_clr_df = pd.read_csv(base_file_path + "genus.clr.csv")
genus_count_df = pd.read_csv(base_file_path + "genus.count.csv")
genus_ra_df = pd.read_csv(base_file_path + "genus.ra.csv")

sp_clr_df = pd.read_csv(base_file_path + "sp.clr.csv")
sp_count_df = pd.read_csv(base_file_path + "sp.count.csv")
sp_ra_df = pd.read_csv(base_file_path + "sp.ra.csv")

genus_df_list = [genus_clr_df, genus_count_df, genus_ra_df]
sp_df_list = [sp_clr_df, sp_count_df, sp_ra_df]

taxa_dict = {
    "genus": genus_df_list,
    "species": sp_df_list
}


# In[3]:
########################################
###
###       Merge Metadata Preprocessing
###
########################################

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

# merge_meta_df contains the metadata for the drift data
# for i in merge_meta_df.columns:
#     print(i)

# In[4]:
########################################
###
###      Taxa Data Preprocessing
###
########################################

for taxa, taxa_df_list in taxa_dict.items():

    for idx, df in enumerate(taxa_df_list):

        baseline_data = prepare_baseline_data(df)
        taxa_dict[taxa][idx] = baseline_data

# In[5]:    
########################################
###
###             Data Cleaning
###
########################################

# Check for missing values in merge_meta_df in each column
# for col in merge_meta_df.columns:
#     missing_count = merge_meta_df[col].isnull().sum()
#     if missing_count > 0:
#         print(f"Column: {col} has {missing_count} missing values.")

# check to see if the missing values are in the same rows
# missing_rows = merge_meta_df[merge_meta_df.isnull().any(axis=1)]
# print(missing_rows)

# do we want to remove the patients that don't have consent?
# print(merge_meta_df['consent'].value_counts())

# the genus and the species data does not contain any missing values
# so we do not need to worry about that

# print(merge_meta_df.dtypes)

# for taxa, taxa_df_list in taxa_dict.items():
# 
#     for idx, df in enumerate(taxa_df_list):
# 
#         print(f"Taxa: {taxa}, Index: {idx}")
#         print(df.dtypes)

# In[6]:
########################################
###
###             Data Merging
###
########################################

# our X data is each of the taxa dataframes
# our y data is the merge_meta_df['differences_BL_BMI']
# merge_meta_df['differences_BL_BMI'] is the target variable

y = merge_meta_df['differences_BL_BMI']
X = taxa_dict['genus'][0].iloc[:, 1:] # remove the subjectid column

# Set the number of top features you want to select
n_to_select = 100  # Adjust this number as needed
seed = 42  

# Run Random Forest
top_features_rf, rf_model = run_rf(n_to_select, X, y, test_size=0.3, random_state=seed) 
print("Top features from Random Forest:", top_features_rf)

# Run Extra Trees Classifier
top_features_et, etc_model = Run_ETC(n_to_select, X, y, seed_value=seed)  # Example seed value
print("Top features from Extra Trees Classifier:", top_features_et)

# Run Recursive Feature Elimination
top_features_rfe, rfe_model = Run_RFE(n_to_select, X, y, flip=False)  # Set flip as needed
print("Top features from RFE:", top_features_rfe)

# Run ANOVA
top_features_anova, anova_model = Run_ANOVA(n_to_select, X, y, flip=True)  # Set flip as needed
print("Top features from ANOVA:", top_features_anova)

# Run Lasso
top_features_lasso, lasso_model = Run_Lasso(n_to_select, X, y, flip=True, seed=seed)  # Set flip as needed
print("Top features from Lasso:", top_features_lasso)

# In[7]:
########################################
###
###             Plotting
###
########################################

# Example feature sets (replace these with your actual top feature lists)
top_features_rf = set(top_features_rf)  # Random Forest
top_features_et = set(top_features_et)  # Extra Trees Classifier
top_features_rfe = set(top_features_rfe)  # RFE
top_features_anova = set(top_features_anova)  # ANOVA
top_features_lasso = set(top_features_lasso)  # Lasso


# Put feature sets in a dictionary
feature_sets = {
    'Random Forest': top_features_rf,
    'Extra Trees': top_features_et,
    'RFE': top_features_rfe,
    'ANOVA': top_features_anova,
    'Lasso': top_features_lasso
}

# Create a figure with subplots (adjust size and layout to fit all diagrams)
fig, axes = plt.subplots(5, 4, figsize=(20, 25))  # 5 rows, 4 columns for 20 combinations
axes = axes.flatten()

# Pairwise Venn Diagrams
pairwise_combos = list(combinations(feature_sets.keys(), 2))
for i, (set1, set2) in enumerate(pairwise_combos):
    venn2([feature_sets[set1], feature_sets[set2]], set_labels=(set1, set2), ax=axes[i])

# Triple Venn Diagrams
triple_combos = list(combinations(feature_sets.keys(), 3))
for i, (set1, set2, set3) in enumerate(triple_combos, len(pairwise_combos)):
    venn3([feature_sets[set1], feature_sets[set2], feature_sets[set3]], set_labels=(set1, set2, set3), ax=axes[i])

# Adjust layout and save the figure
plt.tight_layout()
plt.savefig('figures/venn_diagram.png')
plt.show()
