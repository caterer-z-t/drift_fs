# In[1]:
########################################
###
###             Imports
###
########################################

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
plt.style.use('ggplot')
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

from numpy import genfromtxt
import csv 
# from matplotlib_venn import venn3
# from matplotlib_venn import venn2
# import venn

# ExtraTreesClassifier imports
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.datasets import make_classification

# Recursive Feature Selection imports
from sklearn.feature_selection import RFE
from sklearn.svm import SVR

# ANOVA imports
from sklearn.feature_selection import SelectKBest, f_classif

from utils.utils import *

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
###             Functions
###
########################################

# please see the utils.py file for the functions

# In[4]:
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

# In[5]:
########################################
###
###      Taxa Data Preprocessing
###
########################################

for taxa, taxa_df_list in taxa_dict.items():

    for idx, df in enumerate(taxa_df_list):

        baseline_data = prepare_baseline_data(df)
        taxa_dict[taxa][idx] = baseline_data

# In[6]:    
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

# In[7]:
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

print(X.shape)
print(y.shape)

print(X.head())
print(X.dtypes)
print(y)

# Assuming y and X are already defined as per your provided code

# Split the dataset
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Train the Random Forest model
rf = RandomForestRegressor(n_estimators=100, random_state=42)
rf.fit(X_train, y_train)

# Evaluate the model
accuracy_before = rf.score(X_test, y_test)
print(f'R^2 Score before feature selection: {accuracy_before:.2f}')

# Extract feature importances
importances = rf.feature_importances_
feature_names = X.columns
feature_importance_df = pd.DataFrame({'Feature': feature_names, 'Importance': importances})

# Rank features by importance
feature_importance_df = feature_importance_df.sort_values(by='Importance', ascending=False)
print(feature_importance_df)

# Select top N features (example selecting top 10 features)
top_features = feature_importance_df['Feature'][:10].values
X_train_selected = X_train[top_features]
X_test_selected = X_test[top_features]

# Train the Random Forest model with selected features
rf_selected = RandomForestRegressor(n_estimators=100, random_state=42)
rf_selected.fit(X_train_selected, y_train)

# Evaluate the model
accuracy_after = rf_selected.score(X_test_selected, y_test)
print(f'R^2 Score after feature selection: {accuracy_after:.2f}')
