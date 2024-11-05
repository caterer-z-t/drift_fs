# In[1]: Imports

import pandas as pd
from pathlib import Path

# In[2]: Load Data
# Get the directory of the current script and append the relative path to stanislawski_lab_data
base_file_path = Path("/Users/zaca2954/stanislawski_lab/stanislawski_lab_data")

# Load Data
merge_meta_df = pd.read_csv(base_file_path / "merge_meta_methyl.csv")
genus_clr_df = pd.read_csv(base_file_path / "genus.clr.csv")


# removing these datasets becuase the count df and ra df are just transformations to aquire the clr df
genus_count_df = pd.read_csv(base_file_path / "genus.count.csv")
genus_ra_df = pd.read_csv(base_file_path / "genus.ra.csv")

# removing the specices df because we want to focus on the analysis of the genus data for now, could include this later
sp_clr_df = pd.read_csv(base_file_path / "sp.clr.csv")
sp_count_df = pd.read_csv(base_file_path / "sp.count.csv")
sp_ra_df = pd.read_csv(base_file_path / "sp.ra.csv")

taxa_dict = {
    "genus": {"clr": genus_clr_df, "count": genus_count_df, "ra": genus_ra_df},
    "species": {"clr": sp_clr_df, "count": sp_count_df, "ra": sp_ra_df},
}

# In[3]: Functions

def merge_dataframes(genus, meta):

    # modify genus data sampleid names
    genus[["subject_id", "time_series"]] = genus["SampleID"].str.split(".", expand=True)

    # Filter genus_clr_df for rows where 'time_series' is 'BL' (baseline data)
    genus = genus[genus["time_series"] == "BL"]
    genus.drop(columns=["SampleID", "time_series"], inplace=True)

    # merge the two dataframes on the sample_id column
    merged_df = pd.merge(meta, genus, on="subject_id", how="inner")
    merged_df.drop(columns=["subject_id"], inplace=True)

    return merged_df


def obtain_just_species_and_genus_data(df):
    # get the species and genus columns
    species_genus_df = df.loc[:, df.columns.str.contains("__")]

    # append the differences_BL_BMI
    species_genus_df["differences_BL_BMI"] = df["differences_BL_BMI"]

    return species_genus_df


def obtain_just_latent_data(df):
    # get a list of all the columns that are not species or genus
    latent_df = df.loc[:, ~df.columns.str.contains("__")]

    # append the differences_BL_BMI
    latent_df["differences_BL_BMI"] = df["differences_BL_BMI"]

    return latent_df


# In[4]: Data Exploration

# remove all the columns containing ['3m', '6m', '12m', '18m']
# this is because this is the timeseries data and for right now
# we only have the baseline data
for col in merge_meta_df.columns:
    if any(
        x in col
        for x in [
            "Unnamed: 0",
            "3m",
            "6m",
            "12m",
            "18m",
            "PC",
            "pc",
            "bug",
            "array",
            "sex.y",
            "age.y",
            "cohort",
            "race.y",
            "ethnicity.y",
            "timepoint",
            "duplicate_sample",
            "SampleID",
            "outcome_bmi_current",
            "sample_name",
            "sentrix",
            "mrs.wt",
            "mrs.std.wt",
            "start_treatment",
            "withdrawal_date_check",
        ]
    ):  # have I removed anything I shouldn't have?
        merge_meta_df = merge_meta_df.drop(columns=[col])

# remove consent = no
# if we decide to use this data we can include it later
# just comment this out
merge_meta_df = merge_meta_df[merge_meta_df["consent"] == "yes"]

# columns to use
columns = [
    "subject_id",
    "gender",  # what are these values, they are currently binary
    "age.x",
    "race.x",  # what are these values, they are numerical before preprocessing?
    # 'race_fact',   # these are the same but these values are categorical
    "ethnicity.x",  # what are these values, they are numerical before preprocessing?
    "education",  # what are these values, they are numerical before preprocessing?
    # 'job_activity',   # what are these values, they are numerical before preprocessing?
    # 'income',         # what are these values, they are numerical before preprocessing?
    # 'marital_status', # what are these values, they are numerical before preprocessing?
    "height_inches",
    "rmr_kcald_BL",
    "spk_EE_int_kcal_day_BL",
    "avg_systolic_BL",
    "avg_diastolic_BL",
    "C_Reactive_Protein_BL",
    "Cholesterol_lipid_BL",
    "Ghrelin_BL",
    "Glucose_BL",
    "HDL_Total_Direct_lipid_BL",
    "Hemoglobin_A1C_BL",
    "Insulin_endo_BL",
    "LDL_Calculated_BL",
    "Leptin_BL",
    "Peptide_YY_BL",
    "Triglyceride_lipid_BL",
    "HOMA_IR_BL",
    "differences_BL_BMI",
]

# remove if consent was no
merge_meta_df = merge_meta_df[merge_meta_df["consent"] == "yes"]

# filter the columns of the meta data to only include
# the columns that are in the columns list
merge_meta_df = merge_meta_df[columns]

# TODO: Normalize the data? I dont know for sure if this is necessary
# each method we use for classification will have its own normalization method

# In[5]: Merge and Save Data

for idx, taxa in enumerate(taxa_dict.keys()):
    for idy, taxa_transform in enumerate(taxa_dict[taxa].keys()):
        data = merge_dataframes(taxa_dict[taxa][taxa_transform], merge_meta_df.copy())
        taxa_dict[taxa][taxa_transform] = {"latent_and_genus_species": data}

        # save the data
        data.to_csv(base_file_path / f"{taxa}_{taxa_transform}.csv", index=False)

        # get the species and genus data
        taxa_dict[taxa][taxa_transform]["species_genus"] = (
            obtain_just_species_and_genus_data(data)
        )

        # get the latent data
        taxa_dict[taxa][taxa_transform]["latent"] = obtain_just_latent_data(data)

