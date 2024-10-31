import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
plt.style.use('ggplot')

def toSet(current_data, n_to_select):
    current_data = list(np.asarray(current_data, dtype = 'int'))
    current_data = current_data[0:n_to_select]
    set_output = set(current_data)
    return set_output

def remove_unnamed_columns(df):
    return df.drop(columns=['Unnamed: 0'])

def check_sample_id_column(df):
    """Check if 'SampleID' column exists in the dataframe."""
    if 'SampleID' in df.columns:
        return True
    else:
        print("No 'SampleID' column found in the dataframe.")
        return False

def extract_baseline_rows(df):
    """Extract rows where 'SampleID' contains 'BL'."""
    return df[df['SampleID'].str.contains('BL')].copy()

def remove_bl_suffix(df):
    """Remove the '.BL' suffix from the 'SampleID' column."""
    df['SampleID'] = df['SampleID'].str.replace('.BL', '', regex=False)
    return df

def remove_unnamed_columns(df):
    """Remove 'Unnamed: 0' column if it exists."""
    if 'Unnamed: 0' in df.columns:
        return df.drop(columns=['Unnamed: 0'], inplace=False)
    return df

def prepare_baseline_data(df):
    """Combines all steps to prepare the baseline data."""
    if check_sample_id_column(df):
        baseline_data = extract_baseline_rows(df)
        baseline_data = remove_bl_suffix(baseline_data)
        return remove_unnamed_columns(baseline_data)
    return df

def get_feature_importances(model):
    """Get the feature importances from the fitted model."""
    return model.feature_importances_

def rank_features(feature_importances):
    """Rank the features based on their importances."""
    return np.argsort(feature_importances)

def select_top_features(sorted_indices, n_to_select):
    """Select the top features based on the number specified."""
    return sorted_indices[:n_to_select]  # Assuming toSet is similar to slicing here

def flip_indices_if_needed(indices, flip):
    """Flip the indices array if specified."""
    return np.flip(indices) if flip else indices

def merge_dataframes(genus, meta):
    """Merge the genus and metadata dataframes.

    Args:
        genus (dataframe): Genus or species data. 
        meta (dataframe): Metadata.

    Returns:
        dataframe: Merged dataframe.
    """
    # modify genus data sampleid names
    genus[['subject_id', 'time_series']] = genus['SampleID'].str.split('.', expand=True)    
    
    # Filter genus_clr_df for rows where 'time_series' is 'BL' (baseline data)
    genus = genus[genus['time_series'] == 'BL']
    genus.drop(columns=['SampleID', 'time_series'], inplace=True)
    
    # merge the two dataframes on the sample_id column
    merged_df = pd.merge(meta, genus, on='subject_id', how='inner')
    merged_df.drop(columns=['subject_id'], inplace=True)
    
    return merged_df

def remove_columns_from_df(dataframe, columns):
    """Remove columns from the dataframe."""
    for col in dataframe.columns:
        if any(x in col for x in columns): 
            dataframe = dataframe.drop(columns=[col])

    return dataframe

def keep_columns(dataframe, columns):
    """Keep only the specified columns in the dataframe."""
    return dataframe[columns]