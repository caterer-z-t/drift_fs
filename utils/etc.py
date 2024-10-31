from sklearn.ensemble import ExtraTreesRegressor
from utils.utils import get_feature_importances, rank_features, flip_indices_if_needed, select_top_features

def fit_etc_model(indColumn, targetColumn, seed_value):
    """Fit the Extra Trees Regressor model."""
    model = ExtraTreesRegressor(random_state=seed_value)
    model.fit(indColumn, targetColumn)
    return model

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
    
    return set_output, etc_model
