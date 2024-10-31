# Recursive Feature Selection imports
from sklearn.feature_selection import RFE
from sklearn.svm import SVR
from utils.utils import rank_features, flip_indices_if_needed, select_top_features

def get_rfe_ranking(rfe_model):
    """Get the ranking of features from the fitted RFE model."""
    return rfe_model.ranking_

def fit_rfe_model(indColumn, targetColumn, n_to_select):
    """Fit the Recursive Feature Elimination model."""
    estimator = SVR(kernel="linear")
    rfe_model = RFE(estimator, n_features_to_select=n_to_select, step=1)
    rfe_model.fit(indColumn, targetColumn)
    return rfe_model

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
    
    return set_output, rfe_model
