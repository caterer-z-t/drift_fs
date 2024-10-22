from sklearn.ensemble import RandomForestRegressor
from utils.utils import get_feature_importances, rank_features, select_top_features

def fit_rf_model(indColumn, targetColumn, n_estimators=100, random_state=None):
    """Fit the Random Forest Regressor model."""
    model = RandomForestRegressor(n_estimators=n_estimators, random_state=random_state)
    model.fit(indColumn, targetColumn)
    return model


def run_rf(n_to_select, indColumn, targetColumn, test_size=0.3, random_state=None):
    """Run the Random Forest model and return the top features."""
    # Fit the Random Forest model
    rf_model = fit_rf_model(indColumn, targetColumn)
    
    # Get feature importances
    feature_importances = get_feature_importances(rf_model)
    
    # Rank features
    sorted_indices = rank_features(feature_importances)
    
    # Select top features
    set_output = select_top_features(sorted_indices, n_to_select)
    
    return set_output, rf_model  
