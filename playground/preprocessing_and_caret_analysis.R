# In[1]: Imports ----

rm(list = ls())

library(caret)
library(readr)
library(plyr)
library(dplyr)
library(tidyr)
library(purrr)
library(tibble)
library(stringr)
library(psych)
library(randomForest)
library(glmnet)
library(xgboost)

# install.packages('glmnet')

# In[2]: Data Imports ----
base_path <- base_path_locally <- '/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/drift_fs/csv/'
# base_path <- base_path_fiji <- "/Users/zaca2954/stanislawski_lab/drift_fs/csv/"

updated_analysis <- read_csv(paste0(base_path, "grs.diff_110324.csv"))
genus_clr_data <- read_csv(paste0(base_path, "genus.clr.csv"))
species_clr_data <- read_csv(paste0(base_path, "sp.clr.csv"))
merge_metadata <- read_csv(paste0(base_path, "merge_meta_methyl.csv"))
metadata <- read_csv(paste0(base_path, "/DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv"))

# In[3]: Functions ----
make_new_columns <- function(data, column_name) {
  data <- data %>%
    mutate(subject_id = str_split(column_name, "\\.", simplify = TRUE)[, 1],
           TIMEPOINT = str_split(column_name, "\\.", simplify = TRUE)[, 2])
  return(data)
}

filter_data <- function(data, column, value) {
  data <- data %>%
    filter(column == value)
  return(data)
}

merge_data <- function(data1, data2, join_type, columnname) {
    data <- join_type(data1, data2, by = columnname)
    
    # Remove the duplicated columns and rename as necessary
    data <- data %>%
      select(-matches(paste0(columnname, "\\.y$"))) %>%
      rename_with(~ gsub("\\.x$", "", .), ends_with(".x")) 
    
    return(data)
}

remove_columns <- function(data, columns_to_remove) {
  data %>% select(-all_of(columns_to_remove))
}

extract_certain_columns <- function(data, columns_to_extract) {
  data %>% select(all_of(columns_to_extract))
}

train_model <- function(data, formula, method, trControl, tuneGrid = NULL) {
  train(formula, data = data, method = method, trControl = trControl, tuneGrid = tuneGrid)
}

train_all_models <- function(data, target_var, train_control) {
  formula <- as.formula(paste(target_var, "~ ."))

  # Train individual models
  rf_model <- train_model(data, formula, "rf", train_control)
  lasso_model <- train_model(
    data, formula, "glmnet", train_control,
    expand.grid(alpha = 1, lambda = seq(0.001, 0.1, length = 10))
  )
  ridge_model <- train_model(
    data, formula, "glmnet", train_control,
    expand.grid(alpha = 0, lambda = seq(0.001, 0.1, length = 10))
  )
  enet_model <- train_model(
    data, formula, "glmnet", train_control,
    expand.grid(alpha = 0.5, lambda = seq(0.001, 0.1, length = 10))
  )
  xgboost_model <- train_model(data, formula, "xgbTree", train_control)

  return(list(
    rf_model = rf_model,
    lasso_model = lasso_model,
    ridge_model = ridge_model,
    enet_model = enet_model,
    xgboost_model = xgboost_model
  ))
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

process_data <- function(data, columns_to_remove, columns_to_standardize, impute_method = "medianImpute") {
  data_cleaned <- remove_columns(data, columns_to_remove)
  data_standardized <- preprocess_data(data_cleaned, columns_to_standardize, impute_method)
  return(data_standardized)
}

# Helper function to calculate model performance metrics for either training or testing data
calculate_metrics <- function(model, data, target_var, model_name, data_type) {
  predictions <- predict(model, data)
  actuals <- data[[target_var]]

  r2 <- caret::R2(predictions, actuals)
  mae <- caret::MAE(predictions, actuals)
  rmse <- caret::RMSE(predictions, actuals)

  return(data.frame(Model = model_name, DataType = data_type, R2 = r2, MAE = mae, RMSE = rmse))
}

# Update the train_and_save_models function to include training and testing metric calculation
train_and_save_models <- function(data, target_var, train_control, result_prefix, test_size = 0.3) {
  # Split data into training and testing sets
  set.seed(123) # Ensure reproducibility
  train_indices <- sample(seq_len(nrow(data)), size = (1 - test_size) * nrow(data))
  train_data <- data[train_indices, ]
  test_data <- data[-train_indices, ]

  # Train models
  results <- train_all_models(train_data, target_var, train_control)

  # Extract and save feature importance
  feature_importance <- combine_importances(
    results,
    c("RF_Importance", "Lasso_Importance", "Ridge_Importance", "Enet_Importance", "XGBoost_Importance")
  )
  write.csv(feature_importance, paste0("drift_fs/csv/", result_prefix, "_feature_importance.csv"), row.names = FALSE)

  # Extract and save beta coefficients
  beta_coefficients <- extract_best_betas(
    list(results$lasso_model, results$ridge_model, results$enet_model),
    c("Lasso_Beta", "Ridge_Beta", "Enet_Beta")
  )
  write.csv(beta_coefficients, paste0("drift_fs/csv/", result_prefix, "_beta.csv"), row.names = FALSE)

  # Initialize an empty DataFrame to store performance metrics
  metrics_df <- data.frame(Model = character(), DataType = character(), R2 = numeric(), MAE = numeric(), RMSE = numeric(), stringsAsFactors = FALSE)

  # Calculate and store metrics for each model on both training and testing data
  for (model_name in names(results)) {
    model <- results[[model_name]]

    # Training metrics
    train_metrics <- calculate_metrics(model, train_data, target_var, model_name, "Train")
    metrics_df <- rbind(metrics_df, train_metrics)

    # Testing metrics
    test_metrics <- calculate_metrics(model, test_data, target_var, model_name, "Test")
    metrics_df <- rbind(metrics_df, test_metrics)
  }

  # Save the metrics DataFrame as CSV
  write.csv(metrics_df, paste0("drift_fs/csv/", result_prefix, "_metrics.csv"), row.names = FALSE)

  # Save model results
  saveRDS(results, paste0("drift_fs/models/", result_prefix, "_results.rds"))

  return(results)
}

# In[4]: Data Preprocessing ----

# In[4.1]: Process genus and species clr data ----

genus_clr_data <- make_new_columns(genus_clr_data, genus_clr_data$SampleID)

genus_clr_data <- filter_data(genus_clr_data, genus_clr_data$TIMEPOINT, "BL")

# In[4.2]: Merge the updated_analysis and metadata ----

# Ensure both datasets have 'record_id' for the join
meta_data <- merge_data(updated_analysis, metadata %>% select(-subject_id), inner_join, "record_id")

merge_meta_data <- merge_metadata %>%
  select(subject_id, predicted_BL_BMI, differences_BL_BMI, diff_BMI_quartile, diff_BMI_std)

# append the columns of merge_meta_data to meta_data
meta_data_df <- cbind(meta_data, merge_meta_data %>% select(-subject_id))

# only keep the consented samples
meta_data_df <- filter_data(meta_data_df, meta_data_df$consent, "yes")

# In[4.3]: Merge the genus and species clr data with the metadata ----

genus_clr_data <- merge_data(genus_clr_data, meta_data_df, inner_join, "subject_id")

rm(meta_data_df, meta_data, merge_meta_data, metadata, merge_metadata)

# In[4.4]: Remove the columns that are not needed ----

# remove any of the columns that are not needed
genus_clr_data <- genus_clr_data %>%
  select(-matches("3m|6m|12m|18m"),
  -SampleID, -TIMEPOINT, -record_id, 
  -withdrawal_date_check, -start_treatment, -...1)

# In[4.5]: Finalize Genus and Species datasets ----

# columns we want to use in the analysis
# any column that contains "__"
latent_variables_to_use <- c(
  "subject_id",
  "age",
  "sex",
  "cohort_number",
  "race",
  "ethnicity",
  "education",
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

  # prediction variables for the regression model are
  # "differences_BL_BMI",
  "diff_std_bmi_score"
)

mimimum_columns_to_use <- c(
  "subject_id",
  "age",
  "sex",
  "cohort_number",
  "race", 
  "ethnicity",
  "education",

  "diff_std_bmi_score"
)

# ensure all the columns are present in the data
genus_clr_latent <- genus_clr_data %>% select(all_of(latent_variables_to_use), matches("__"))
genus_minimal <- genus_clr_data %>% select(all_of(mimimum_columns_to_use), matches("__"))

# In[5]: Main Data Processing ----

columns_to_remove <- c("subject_id")
columns_to_standardize <- latent_variables_to_use[-1]
minimal_columns_to_standardize <- mimimum_columns_to_use[-1]

genus_clr_latent_cleaned <- remove_columns(genus_clr_latent, columns_to_remove)
genus_clr_latent_standardized <- preprocess_data(genus_clr_latent_cleaned, columns_to_standardize, "medianImpute")

genus_minimal_cleaned <- remove_columns(genus_minimal, columns_to_remove)
genus_minimal_standardized <- preprocess_data(genus_minimal_cleaned, minimal_columns_to_standardize, "medianImpute")

# In[6]: Model Training ----
set.seed(123)
train_control <- trainControl(method = "cv", number = 5)

# Process and train on genus_clr_latent data
genus_clr_latent_standardized <- process_data(genus_clr_latent, columns_to_remove, columns_to_standardize)
results_latent <- train_and_save_models(genus_clr_latent_standardized, "diff_std_bmi_score", train_control, "latent")

# process the latent factors only
latent_no_genus <- remove_columns(genus_clr_latent_standardized, matches("__"))
latent_results <- train_and_save_models(latent_no_genus, "diff_std_bmi_score", train_control, "latent_no_genus")

# Process and train on genus_clr_latent data without standard columns
genus_clr_latent_no_standard <- remove_columns(genus_clr_latent_standardized, columns_to_standardize[-length(columns_to_standardize)])
results_no_latent <- train_and_save_models(genus_clr_latent_no_standard, "diff_std_bmi_score", train_control, "no_latent")

# Process and train on genus_minimal data
genus_minimal_standardized <- process_data(genus_minimal, columns_to_remove , minimal_columns_to_standardize)
minimal_results_latent <- train_and_save_models(genus_minimal_standardized, "diff_std_bmi_score", train_control, "minimal_latent")

# Process just the latent and minimal latent factors
# keep the minimal columns only (not including the genus columns -- columns containing "__")
genus_minimal_no_genus <- remove_columns(genus_minimal_standardized, matches("__"))
minimal_results_no_latent <- train_and_save_models(genus_minimal_no_genus, "diff_std_bmi_score", train_control, "minimal_no_genus")
