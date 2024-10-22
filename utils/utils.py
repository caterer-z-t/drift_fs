import numpy as np
import matplotlib.pyplot as plt
plt.style.use('ggplot')


# from matplotlib_venn import venn3
# from matplotlib_venn import venn2
# import venn

# ExtraTreesClassifier imports
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

# Recursive Feature Selection imports
from sklearn.feature_selection import RFE
from sklearn.svm import SVR

# ANOVA imports
from sklearn.feature_selection import SelectKBest, f_classif

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

def get_rfe_ranking(rfe_model):
    """Get the ranking of features from the fitted RFE model."""
    return rfe_model.ranking_

def flip_indices_if_needed(indices, flip):
    """Flip the indices array if specified."""
    return np.flip(indices) if flip else indices

def get_anova_scores(anova_model):
    """Get the ANOVA scores from the fitted model."""
    anova_scores = -np.log10(anova_model.pvalues_)
    anova_scores /= anova_scores.max()
    return anova_scores

# fit models

def fit_anova_model(indColumn, targetColumn, k=4):
    """Fit the ANOVA model."""
    anova_model = SelectKBest(f_classif, k=k)
    anova_model.fit(indColumn, targetColumn)
    return anova_model

def fit_rfe_model(indColumn, targetColumn, n_to_select):
    """Fit the Recursive Feature Elimination model."""
    estimator = SVR(kernel="linear")
    rfe_model = RFE(estimator, n_features_to_select=n_to_select, step=1)
    rfe_model.fit(indColumn, targetColumn)
    return rfe_model

def fit_etc_model(indColumn, targetColumn, seed_value):
    """Fit the Extra Trees Classifier model."""
    model = ExtraTreesClassifier(random_state=seed_value)
    model.fit(indColumn, targetColumn)
    return model

def fit_rf_model(indColumn, targetColumn, n_estimators=100, random_state=None):
    """Fit the Random Forest Regressor model."""
    model = RandomForestRegressor(n_estimators=n_estimators, random_state=random_state)
    model.fit(indColumn, targetColumn)
    return model

# Run Models

def Run_ETC(n_to_select, indColumn, targetColumn, seed_value, flip=True):
    """Run the ETC model and return the top features."""
    # Fit the model
    etc_model = fit_etc_model(indColumn, targetColumn, seed_value)
    
    # Get feature importances
    feature_importances = get_feature_importances(etc_model)
    
    # Rank features
    sorted_indices = rank_features(feature_importances)
    
    # Flip sorted indices if necessary
    sorted_indices = flip_indices_if_needed(sorted_indices, flip)
    
    # Select top features
    set_output = select_top_features(sorted_indices, n_to_select)
    
    return set_output

def Run_RFE(n_to_select, indColumn, targetColumn, flip=False):
    """Run the RFE model and return the top features."""
    # Fit the RFE model
    rfe_model = fit_rfe_model(indColumn, targetColumn, n_to_select)
    
    # Get feature rankings
    rfe_output = get_rfe_ranking(rfe_model)
    
    # Rank features
    sorted_indices = rank_features(rfe_output)
    
    # Flip sorted indices if necessary
    sorted_indices = flip_indices_if_needed(sorted_indices, flip)
    
    # Select top features
    set_output = select_top_features(sorted_indices, n_to_select)
    
    return set_output

def Run_ANOVA(n_to_select, indColumn, targetColumn, flip=True):
    """Run the ANOVA model and return the top features."""
    # Fit the ANOVA model
    anova_model = fit_anova_model(indColumn, targetColumn)
    
    # Get ANOVA scores
    anova_scores = get_anova_scores(anova_model)
    
    # Rank features
    sorted_indices = rank_features(anova_scores)
    
    # Flip sorted indices if necessary
    sorted_indices = flip_indices_if_needed(sorted_indices, flip)
    
    # Select top features
    set_output = select_top_features(sorted_indices, n_to_select)
    
    return set_output

def run_rf(n_to_select, indColumn, targetColumn, test_size=0.3, random_state=None):
    """Run the Random Forest model and return the top features."""
    # Split the dataset into training and test sets
    X_train, X_test, y_train, y_test = train_test_split(indColumn, targetColumn, test_size=test_size, random_state=random_state)
    
    # Fit the Random Forest model
    rf_model = fit_rf_model(X_train, y_train)
    
    # Get feature importances
    feature_importances = get_feature_importances(rf_model)
    
    # Rank features
    sorted_indices = rank_features(feature_importances)
    
    # Select top features
    set_output = select_top_features(sorted_indices, n_to_select)
    
    return set_output, rf_model  # Return the selected features and the fitted model

# Example of how to call the function:
# Assuming you have your independent and target data prepared:
# selected_features, rf_model = run_rf(n_to_select=10, indColumn=X, targetColumn=y)
