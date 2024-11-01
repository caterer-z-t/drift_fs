"""
this code was written as a playground for the feature selection 
of the drift dataset. 

The code is not meant to be run as a script, but rather to be
copied and pasted into a jupyter notebook or an interactive
python session. however since I am using python notebook through 
alpine I am unable to run the code in a notebook.

for help please see the readme file in the same directory

author: caterer-z-t
email: ztcaterer@colorado.edu
"""

#######################################################
###
###                Imports
###
#######################################################

import pandas as pd
# import numpy as np
# import matplotlib.pyplot as plt
# import seaborn as sns

#######################################################
###
###                Load Data
###
#######################################################

base_file_path = "/home/zaca2954/iq_bio/stanislawski_lab/stanislawski_lab_data/"

# drift_metadata = pd.read_csv(base_file_path + "DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv")
merge_meta_df = pd.read_csv(base_file_path + "merge_meta_methyl.csv") # is the merged dataset with the drift information

genus_clr_df = pd.read_csv(base_file_path + "genus.clr.csv")
genus_count_df = pd.read_csv(base_file_path + "genus.count.csv")
genus_ra_df = pd.read_csv(base_file_path + "genus.ra.csv")

sp_clr_df = pd.read_csv(base_file_path + "sp.clr.csv")
sp_count_df = pd.read_csv(base_file_path + "sp.count.csv")
sp_ra_df = pd.read_csv(base_file_path + "sp.ra.csv")

#######################################################
###
###                functions
###
#######################################################

# list of all the columns in the dataframe, and list of all columns contining nan values
def get_nan_columns(df):
    nan_columns = []
    for column in df.columns:
        if df[column].isnull().values.any():
            nan_columns.append(column)
    return nan_columns

def get_column_types(df):
    column_types = {}
    for column in df.columns:
        column_types[column] = df[column].dtype
    return column_types

#######################################################
###
###                Data Exploration
###
#######################################################

# merge_meta_df
print("merge_meta_df")
print(merge_meta_df.head())
print(merge_meta_df.shape)
print(merge_meta_df.columns)
print(merge_meta_df.dtypes)
print(merge_meta_df.describe())
# print the functions get column types but each entry is new line
for i in get_column_types(merge_meta_df):
    print(i, get_column_types(merge_meta_df)[i])
for i in get_nan_columns(merge_meta_df):
    print(i)
print("\n")

## I dont care about clr as it is just a transformation from the RA data
# genus_clr_df
# print("genus_clr_df")
# print(genus_clr_df.head())
# print(genus_clr_df.shape)
# print(genus_clr_df.columns)
# print(genus_clr_df.dtypes)
# print(genus_clr_df.describe())
"""
# genus_count_df
print("genus_count_df")
print(genus_count_df.head())
print(genus_count_df.shape)
print(genus_count_df.columns)
print(genus_count_df.dtypes)
print(genus_count_df.describe())
print(get_column_types(genus_count_df))
print(get_nan_columns(genus_count_df))
print("\n")

# genus_ra_df
print("genus_ra_df")
print(genus_ra_df.head())
print(genus_ra_df.shape)
print(genus_ra_df.columns)
print(genus_ra_df.dtypes)
print(genus_ra_df.describe())
print(get_column_types(genus_ra_df))
print(get_nan_columns(genus_ra_df))
print("\n")

## I dont care about clr as it is just a transformation from the RA data
# sp_clr_df
# print("sp_clr_df")
# print(sp_clr_df.head())
# print(sp_clr_df.shape)
# print(sp_clr_df.columns)
# print(sp_clr_df.dtypes)
# print(sp_clr_df.describe())

# sp_count_df
print("sp_count_df")
print(sp_count_df.head())
print(sp_count_df.shape)
print(sp_count_df.columns)
print(sp_count_df.dtypes)
print(sp_count_df.describe())
print(get_column_types(sp_count_df))
print(get_nan_columns(sp_count_df))
print("\n")

# sp_ra_df
print("sp_ra_df")
print(sp_ra_df.head())
print(sp_ra_df.shape)
print(sp_ra_df.columns)
print(sp_ra_df.dtypes)
print(sp_ra_df.describe())
print(get_column_types(sp_ra_df))
print(get_nan_columns(sp_ra_df))
print("\n")
"""