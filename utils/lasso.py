from sklearn.linear_model import Lasso
from sklearn.feature_selection import SelectFromModel
from utils.utils import rank_features, flip_indices_if_needed, select_top_features

def fit_lasso_model(indColumn, targetColumn, alpha_value=0.1, seed=42):
    """Fit the Lasso regression model."""
    model = Lasso(alpha=alpha_value, random_state=seed)
    model.fit(indColumn, targetColumn)
    return model

def Run_Lasso(n_to_select, indColumn, targetColumn, alpha_value=0.1, flip=True, seed=42):
    """Run the Lasso model and return the top features."""
    # Fit the Lasso model
    lasso_model = fit_lasso_model(indColumn, targetColumn, alpha_value, seed)
    
    # Use SelectFromModel to select important features
    selector = SelectFromModel(lasso_model, prefit=True)
    
    # Get the mask of selected features (True for selected, False for not)
    selected_features = selector.get_support()
    
    # Rank the selected features
    ranked_indices = rank_features(selected_features)
    
    # Flip indices if needed
    ranked_indices = flip_indices_if_needed(ranked_indices, flip)
    
    # Select top features
    set_output = select_top_features(ranked_indices, n_to_select)
    
    return set_output, lasso_model
