from sklearn.feature_selection import SelectKBest, f_classif
from utils.utils import rank_features, flip_indices_if_needed, select_top_features
import numpy as np

def get_anova_scores(anova_model):
    """Get the ANOVA scores from the fitted model."""
    anova_scores = -np.log10(anova_model.pvalues_)
    anova_scores /= anova_scores.max()
    return anova_scores

def fit_anova_model(indColumn, targetColumn, k=4):
    """Fit the ANOVA model."""
    anova_model = SelectKBest(f_classif, k=k)
    anova_model.fit(indColumn, targetColumn)
    return anova_model

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
    
    return set_output, anova_model
