# In[1]: Imports ----
rm(list = ls()) # Clear all objects in the environment

# install.packages("caret", dependencies = c("Depends", "Suggests"))

library(caret)
library(readr)
library(dplyr)
library(psych)
library(purrr)
library(tibble)

# In[2]: Data Imports ----
genus_clr_latent <- read_csv("/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/drift_fs/csv/genus_clr_latent.csv")

# In[3]: Functions ----

remove_columns <- function(data, columns_to_remove) {
  data %>%
    select(-all_of(columns_to_remove))
}

train_models_and_extract_importance <- function(data, target_var, train_control) {
  # Ensure target variable is a formula
  formula <- as.formula(paste(target_var, "~ ."))

  # Train the Random Forest model
  rf_model <- train(
    formula,
    data = data,
    method = "rf",
    trControl = train_control
  )

  # Train the Lasso model
  lasso_model <- train(
    formula,
    data = data,
    method = "glmnet",
    trControl = train_control,
    tuneGrid = expand.grid(alpha = 1, lambda = seq(0.001, 0.1, length = 10))
  )

  # Train the Ridge model
  ridge_model <- train(
    formula,
    data = data,
    method = "glmnet",
    trControl = train_control,
    tuneGrid = expand.grid(alpha = 0, lambda = seq(0.001, 0.1, length = 10))
  )

  # Train the Elastic Net model
  enet_model <- train(
    formula,
    data = data,
    method = "glmnet",
    trControl = train_control,
    tuneGrid = expand.grid(alpha = 0.5, lambda = seq(0.001, 0.1, length = 10))
  )

  return(list(
    rf_model = rf_model,
    lasso_model = lasso_model,
    ridge_model = ridge_model,
    enet_model = enet_model
  ))
}

preprocessing_dataset <- function(data, columns_to_standardize, imputation) {
  # Define the preprocessing parameters
  preprocess_params <- preProcess(data, method = c(imputation)) # knnImpute, meanImpute, or medianImpute
  data_imputed <- predict(preprocess_params, data)

  # Define preprocessing parameters for standardization
  preprocess_params <- preProcess(data_imputed[, columns_to_standardize], method = c("center", "scale"))
  data_standardized <- predict(preprocess_params, data_imputed)

  return(data_standardized)
}

extract_feature_importance <- function(model) {
  importance_df <- as.data.frame(varImp(model)$importance)
  importance_df <- tibble::rownames_to_column(importance_df, var = "Variable") # Convert row names to a column
  return(importance_df)
}

extract_best_beta_values <- function(model) {
  best_lambda <- model$bestTune$lambda
  coef_values <- coef(model$finalModel, s = best_lambda) # Extract coefficients for the best lambda
  return(as.data.frame(as.matrix(coef_values))) # Convert to dataframe
}

# In[4]: Main Data processing ----
columns_to_remove <- c("height_inches", "Unnamed: 0", "subject_id")

columns_to_standardize <- c("gender", "age.x", "race.x", "ethnicity.x", "education", 
                            "rmr_kcald_BL", "spk_EE_int_kcal_day_BL", "avg_systolic_BL", 
                            "avg_diastolic_BL", "C_Reactive_Protein_BL", "Cholesterol_lipid_BL", 
                            "Ghrelin_BL", "Glucose_BL", "HDL_Total_Direct_lipid_BL", 
                            "Hemoglobin_A1C_BL", "Insulin_endo_BL", "LDL_Calculated_BL", 
                            "Leptin_BL", "Peptide_YY_BL", "Triglyceride_lipid_BL", "HOMA_IR_BL")

# Remove the specified columns from the dataset
genus_clr_latent_cleaned <- remove_columns(genus_clr_latent, columns_to_remove)

# Preprocess the dataset
genus_clr_latent_standardized <- preprocessing_dataset(genus_clr_latent_cleaned, columns_to_standardize, "medianImpute")

# In[5]: Train Models with Latent ----
set.seed(123)  # For reproducibility
train_control <- trainControl(method = 'cv', number = 5)
results_latent <- train_models_and_extract_importance(genus_clr_latent_standardized, 
                                               "differences_BL_BMI", 
                                               train_control)
# In[6]: Extract Feature Importance ----
# Extract feature importance for the models with latent
rf_importance_latent <- extract_feature_importance(results_latent$rf_model)
lasso_importance_latent <- extract_feature_importance(results_latent$lasso_model)
ridge_importance_latent <- extract_feature_importance(results_latent$ridge_model)
enet_importance_latent <- extract_feature_importance(results_latent$enet_model)

# Rename columns to avoid conflicts
colnames(rf_importance_latent)[2] <- "RF_Importance"
colnames(lasso_importance_latent)[2] <- "Lasso_Importance"
colnames(ridge_importance_latent)[2] <- "Ridge_Importance"
colnames(enet_importance_latent)[2] <- "Enet_Importance"

# Combine the feature importance for the models with latent into a dataframe
feature_importance_latent <- reduce(
  list(
    rf_importance_latent,
    lasso_importance_latent,
    ridge_importance_latent,
    enet_importance_latent
  ),
  full_join,
  by = "Variable"
)

# Clean up the combined data frame (row names handling is no longer needed)
print(head(feature_importance_latent))
print(dim(feature_importance_latent))

# In[7]: Extract Coefficients ----

# Extract beta values for the models without latent variables
lasso_beta_latent <- extract_best_beta_values(results_latent$lasso_model)
ridge_beta_latent <- extract_best_beta_values(results_latent$ridge_model)
enet_beta_latent <- extract_best_beta_values(results_latent$enet_model)

# Add variable names as a column
lasso_beta_latent$Variable <- rownames(lasso_beta_latent)
ridge_beta_latent$Variable <- rownames(ridge_beta_latent)
enet_beta_latent$Variable <- rownames(enet_beta_latent)

# Rename the beta columns for clarity
colnames(lasso_beta_latent)[1] <- "Lasso_Beta"
colnames(ridge_beta_latent)[1] <- "Ridge_Beta"
colnames(enet_beta_latent)[1] <- "Enet_Beta"

# Combine the beta values into a single dataframe
beta_latent <- reduce(
  list(
    lasso_beta_latent,
    ridge_beta_latent,
    enet_beta_latent
  ),
  full_join,
  by = "Variable"
)

# Reorder columns to make Variable the first column
beta_latent <- beta_latent %>%
  select(Variable, everything())

# Clean up the combined beta dataframe
beta_latent[is.na(beta_latent)] <- 0 # Replace NAs with 0s for clarity

# Print the combined beta values dataframe
print("Combined Beta Values for Models without Latent Variables:")
print(head(beta_latent))
print(dim(beta_latent))

# In[8]: Save Results ----
# Save the results to CSV files
write.csv(feature_importance_latent, "drift_fs/csv/feature_importance_latent.csv", row.names = FALSE)
write.csv(beta_latent, "drift_fs/csv/beta_latent.csv", row.names = FALSE)

# In[9]: Train Models without Latent ----
# remove the columns_to_stndardize
genus_clr_latent_cleaned <- remove_columns(genus_clr_latent_standardized, columns_to_standardize)

set.seed(123) # For reproducibility
results_no_latent <- train_models_and_extract_importance(
  genus_clr_latent_cleaned,
  "differences_BL_BMI",
  train_control
)
# In[10]: Extract Feature Importance ----
# Extract feature importance for the models with latent
rf_importance_no_latent <- extract_feature_importance(results_no_latent$rf_model)
lasso_importance_no_latent <- extract_feature_importance(results_no_latent$lasso_model)
ridge_importance_no_latent <- extract_feature_importance(results_no_latent$ridge_model)
enet_importance_no_latent <- extract_feature_importance(results_no_latent$enet_model)

# Rename columns to avoid conflicts
colnames(rf_importance_no_latent)[2] <- "RF_Importance"
colnames(lasso_importance_no_latent)[2] <- "Lasso_Importance"
colnames(ridge_importance_no_latent)[2] <- "Ridge_Importance"
colnames(enet_importance_no_latent)[2] <- "Enet_Importance"

# Combine the feature importance for the models with latent into a dataframe
feature_importance_no_latent <- reduce(
  list(
    rf_importance_no_latent,
    lasso_importance_no_latent,
    ridge_importance_no_latent,
    enet_importance_no_latent
  ),
  full_join,
  by = "Variable"
)

# Clean up the combined data frame (row names handling is no longer needed)
print(head(feature_importance_no_latent))
print(dim(feature_importance_no_latent))

# In[11]: Extract Coefficients ----

# Extract beta values for the models without latent variables
lasso_beta_no_latent <- extract_best_beta_values(results_no_latent$lasso_model)
ridge_beta_no_latent <- extract_best_beta_values(results_no_latent$ridge_model)
enet_beta_no_latent <- extract_best_beta_values(results_no_latent$enet_model)

# Add variable names as a column
lasso_beta_no_latent$Variable <- rownames(lasso_beta_no_latent)
ridge_beta_no_latent$Variable <- rownames(ridge_beta_no_latent)
enet_beta_no_latent$Variable <- rownames(enet_beta_no_latent)

# Rename the beta columns for clarity
colnames(lasso_beta_no_latent)[1] <- "Lasso_Beta"
colnames(ridge_beta_no_latent)[1] <- "Ridge_Beta"
colnames(enet_beta_no_latent)[1] <- "Enet_Beta"

# Combine the beta values into a single dataframe
beta_no_latent <- reduce(
  list(
    lasso_beta_no_latent,
    ridge_beta_no_latent,
    enet_beta_no_latent
  ),
  full_join,
  by = "Variable"
)

# Reorder columns to make Variable the first column
beta_no_latent <- beta_no_latent %>%
  select(Variable, everything())

# Clean up the combined beta dataframe
beta_no_latent[is.na(beta_no_latent)] <- 0 # Replace NAs with 0s for clarity

# Print the combined beta values dataframe
print("Combined Beta Values for Models without Latent Variables:")
print(head(beta_no_latent))
print(dim(beta_no_latent))

# In[12]: Save Results ----
# Save the results to CSV files

write.csv(feature_importance_no_latent, "drift_fs/csv/feature_importance_no_latent.csv", row.names = FALSE)
write.csv(beta_no_latent, "drift_fs/csv/beta_no_latent.csv", row.names = FALSE)
