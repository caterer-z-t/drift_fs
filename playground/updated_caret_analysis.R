# In[1]: Imports ----
rm(list = ls())

library(caret)
library(readr)
library(dplyr)
library(psych)
library(purrr)
library(tibble)

# In[2]: Data Imports ----
genus_clr_latent <- read_csv("/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/drift_fs/csv/genus_clr_latent.csv")
updated_analysis <- read_csv("/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/drift_fs/csv/grs.diff_110324.csv")
print(head(genus_clr_latent))
print(head(updated_analysis))

# Check for duplicates in genus_clr_latent
sum(duplicated(genus_clr_latent$subject_id))

# Check for duplicates in updated_analysis
sum(duplicated(updated_analysis$subject_id))


# In[2.1]: innerjoing the updated analysis with the genus_clr_latent
genus_clr_latent <- inner_join(genus_clr_latent, updated_analysis, by = "subject_id")

print(head(genus_clr_latent))
# In[3]: Functions ----

remove_columns <- function(data, columns_to_remove) {
  data %>% select(-all_of(columns_to_remove))
}

train_model <- function(data, formula, method, trControl, tuneGrid = NULL) {
  train(formula, data = data, method = method, trControl = trControl, tuneGrid = tuneGrid)
}

train_all_models <- function(data, target_var, train_control) {
  formula <- as.formula(paste(target_var, "~ ."))
  list(
    rf_model = train_model(data, formula, "rf", train_control),
    lasso_model = train_model(
      data, formula, "glmnet", train_control,
      expand.grid(alpha = 1, lambda = seq(0.001, 0.1, length = 10))
    ),
    ridge_model = train_model(
      data, formula, "glmnet", train_control,
      expand.grid(alpha = 0, lambda = seq(0.001, 0.1, length = 10))
    ),
    enet_model = train_model(
      data, formula, "glmnet", train_control,
      expand.grid(alpha = 0.5, lambda = seq(0.001, 0.1, length = 10))
    )
  )
}

preprocess_data <- function(data, columns_to_standardize, imputation_method) {
  data_imputed <- predict(preProcess(data, method = c(imputation_method)), data)
  data_standardized <- predict(preProcess(data_imputed[, columns_to_standardize], method = c("center", "scale")), data_imputed)
  return(data_standardized)
}

extract_importance_df <- function(model, label) {
  importance <- varImp(model)$importance %>%
    as.data.frame() %>%
    rownames_to_column("Variable")
  colnames(importance)[2] <- label
  return(importance)
}

combine_importances <- function(model_list, labels) {
  importance_dfs <- map2(model_list, labels, extract_importance_df)
  reduce(importance_dfs, full_join, by = "Variable")
}

extract_best_betas <- function(model_list, labels) {
  beta_dfs <- map2(model_list, labels, function(model, label) {
    best_lambda <- model$bestTune$lambda
    betas <- as.data.frame(as.matrix(coef(model$finalModel, s = best_lambda))) %>%
      rownames_to_column("Variable")
    colnames(betas)[2] <- label
    return(betas)
  })
  beta_combined <- reduce(beta_dfs, full_join, by = "Variable") %>%
    mutate(across(everything(), ~ replace_na(., 0)))
  return(beta_combined)
}

replace_na <- function(x, value) {
  ifelse(is.na(x), value, x)
}

# In[4]: Main Data Processing ----
columns_to_remove <- c("height_inches", "Unnamed: 0", "subject_id")
columns_to_standardize <- c(
  "gender", "age.x", "race.x", "ethnicity.x", "education",
  "rmr_kcald_BL", "spk_EE_int_kcal_day_BL", "avg_systolic_BL",
  "avg_diastolic_BL", "C_Reactive_Protein_BL", "Cholesterol_lipid_BL",
  "Ghrelin_BL", "Glucose_BL", "HDL_Total_Direct_lipid_BL",
  "Hemoglobin_A1C_BL", "Insulin_endo_BL", "LDL_Calculated_BL",
  "Leptin_BL", "Peptide_YY_BL", "Triglyceride_lipid_BL", "HOMA_IR_BL"
)

genus_clr_latent_cleaned <- remove_columns(genus_clr_latent, columns_to_remove)
genus_clr_latent_standardized <- preprocess_data(genus_clr_latent_cleaned, columns_to_standardize, "medianImpute")

# In[5]: Model Training ----
set.seed(123)
train_control <- trainControl(method = "cv", number = 5)
results_latent <- train_all_models(genus_clr_latent_standardized, "differences_BL_BMI", train_control)

# In[6]: Feature Importance Extraction ----
feature_importance_latent <- combine_importances(results_latent, c("RF_Importance", "Lasso_Importance", "Ridge_Importance", "Enet_Importance"))
print(head(feature_importance_latent))

# In[7]: Beta Coefficients Extraction ----
beta_latent <- extract_best_betas(
  list(results_latent$lasso_model, results_latent$ridge_model, results_latent$enet_model),
  c("Lasso_Beta", "Ridge_Beta", "Enet_Beta")
)
print(head(beta_latent))

# In[8]: Save Results ----
write.csv(feature_importance_latent, "drift_fs/csv/feature_importance_latent.csv", row.names = FALSE)
write.csv(beta_latent, "drift_fs/csv/beta_latent.csv", row.names = FALSE)

# save the models
saveRDS(results_latent, "drift_fs/models/results_latent.rds")

# In[9]: Model Training without Latent Variables ----
genus_clr_latent_cleaned_no_latent <- remove_columns(genus_clr_latent_standardized, columns_to_standardize)
results_no_latent <- train_all_models(genus_clr_latent_cleaned_no_latent, "differences_BL_BMI", train_control)

# In[10]: Feature Importance and Beta Extraction without Latent ----
feature_importance_no_latent <- combine_importances(results_no_latent, c("RF_Importance", "Lasso_Importance", "Ridge_Importance", "Enet_Importance"))
beta_no_latent <- extract_best_betas(
  list(results_no_latent$lasso_model, results_no_latent$ridge_model, results_no_latent$enet_model),
  c("Lasso_Beta", "Ridge_Beta", "Enet_Beta")
)
print(head(feature_importance_no_latent))

# In[11]: Save Results without Latent ----

write.csv(feature_importance_no_latent, "drift_fs/csv/feature_importance_no_latent.csv", row.names = FALSE)
write.csv(beta_no_latent, "drift_fs/csv/beta_no_latent.csv", row.names = FALSE)

# save the models
saveRDS(results_no_latent, "drift_fs/models/results_no_latent.rds")

# In[12]: End ----
