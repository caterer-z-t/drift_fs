# In[1]: Imports ----

rm(list = ls())

library(caret)
library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(tibble)
library(stringr)
library(psych)
library(randomForest)
# library(glmnet)

install.packages('glmnet')

# In[2]: Data Imports ----

updated_analysis <- read_csv("/Users/zaca2954/stanislawski_lab/drift_fs/csv/grs.diff_110324.csv")
genus_clr_data <- read_csv("/Users/zaca2954/stanislawski_lab/stanislawski_lab_data/genus.clr.csv")
species_clr_data <- read_csv("/Users/zaca2954/stanislawski_lab/stanislawski_lab_data/sp.clr.csv")
merge_metadata <- read_csv("/Users/zaca2954/stanislawski_lab/stanislawski_lab_data/merge_meta_methyl.csv")
metadata <- read_csv("/Users/zaca2954/stanislawski_lab/stanislawski_lab_data/DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv")

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

# In[4]: Data Preprocessing ----

# In[4.1]: Process genus and species clr data ----

genus_clr_data <- make_new_columns(genus_clr_data, genus_clr_data$SampleID)
species_clr_data <- make_new_columns(species_clr_data, species_clr_data$SampleID)

genus_clr_data <- filter_data(genus_clr_data, genus_clr_data$TIMEPOINT, "BL")
species_clr_data <- filter_data(species_clr_data, species_clr_data$TIMEPOINT, "BL")

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
species_clr_data <- merge_data(species_clr_data, meta_data_df, inner_join, "subject_id")

rm(meta_data_df, meta_data, merge_meta_data, metadata, merge_metadata)

# In[4.4]: Remove the columns that are not needed ----

# remove any of the columns that are not needed
genus_clr_data <- genus_clr_data %>%
  select(-matches("3m|6m|12m|18m"),
  -SampleID, -TIMEPOINT, -record_id, 
  -withdrawal_date_check, -start_treatment, -...1)

species_clr_data <- species_clr_data %>%
  select(-matches("3m|6m|12m|18m"),
  -SampleID, -TIMEPOINT, -record_id, 
  -withdrawal_date_check, -start_treatment, -...1)

# In[4.5]: Finalize Genus and Species datasets ----

# columns we want to use in the analysis
# any column that contains "__"
# additionally
latent_variables_to_use <- c(
  'subject_id',
  'age',
  'sex',
  'gender',
  'race',
  'ethnicity',
  'education',
  'WBTOT_FAT_BL',
  'WBTOT_LEANmass_BL',
  'WBTOT_BMC_BL',
  'WBTOT_Lean_BMC_BL',
  'WBTOT_PFAT_BL',
  'WBTOT_PLEAN_BL',
  'rmr_kcald_BL',
  'spk_EE_int_kcal_day_BL',
  'avg_systolic_BL',
  'avg_diastolic_BL',
  'C_Reactive_Protein_BL',
  'Cholesterol_lipid_BL',
  'Ghrelin_BL',
  'Glucose_BL',
  'HDL_Total_Direct_lipid_BL',
  'Hemoglobin_A1C_BL',
  'Insulin_endo_BL',
  'LDL_Calculated_BL',
  'Leptin_BL',
  'Peptide_YY_BL',
  'Triglyceride_lipid_BL',
  'HOMA_IR_BL',

  # prediction variables for the regression model are
  'differences_BL_BMI',
  'diff_std_bmi_score'
)

# ensure all the columns are present in the data
genus_clr_latent <- genus_clr_data %>% select(all_of(latent_variables_to_use), matches("__"))
species_clr_latent <- species_clr_data %>% select(all_of(latent_variables_to_use), matches("__"))

# In[5]: Main Data Processing ----

columns_to_remove <- c("subject_id", 'differences_BL_BMI')
columns_to_standardize <- c(
  "gender", "age", "race", "ethnicity", "education",
  "rmr_kcald_BL", "spk_EE_int_kcal_day_BL", "avg_systolic_BL",
  "avg_diastolic_BL", "C_Reactive_Protein_BL", "Cholesterol_lipid_BL",
  "Ghrelin_BL", "Glucose_BL", "HDL_Total_Direct_lipid_BL",
  "Hemoglobin_A1C_BL", "Insulin_endo_BL", "LDL_Calculated_BL",
  "Leptin_BL", "Peptide_YY_BL", "Triglyceride_lipid_BL", "HOMA_IR_BL"
)

genus_clr_latent_cleaned <- remove_columns(genus_clr_latent, columns_to_remove)
genus_clr_latent_standardized <- preprocess_data(genus_clr_latent_cleaned, columns_to_standardize, "medianImpute")

# In[6]: Model Training ----
set.seed(123)
train_control <- trainControl(method = "cv", number = 5)
results_latent <- train_all_models(genus_clr_latent_standardized, 'diff_std_bmi_score', train_control)

# In[7]: Feature Importance Extraction ----
feature_importance_latent <- combine_importances(results_latent, c("RF_Importance", "Lasso_Importance", "Ridge_Importance", "Enet_Importance"))
print(head(feature_importance_latent))

# In[8]: Beta Coefficients Extraction ----
beta_latent <- extract_best_betas(
  list(results_latent$lasso_model, results_latent$ridge_model, results_latent$enet_model),
  c("Lasso_Beta", "Ridge_Beta", "Enet_Beta")
)
print(head(beta_latent))

# In[9]: Save Results ----
write.csv(feature_importance_latent, "drift_fs/csv/feature_importance_latent.csv", row.names = FALSE)
write.csv(beta_latent, "drift_fs/csv/beta_latent.csv", row.names = FALSE)

# save the models
saveRDS(results_latent, "drift_fs/models/results_latent.rds")

# In[10]: Model Training without Latent Variables ----
genus_clr_latent_cleaned_no_latent <- remove_columns(genus_clr_latent_standardized, columns_to_standardize)
results_no_latent <- train_all_models(genus_clr_latent_cleaned_no_latent, 'diff_std_bmi_score', train_control)

# In[11]: Feature Importance and Beta Extraction without Latent ----
feature_importance_no_latent <- combine_importances(results_no_latent, c("RF_Importance", "Lasso_Importance", "Ridge_Importance", "Enet_Importance"))
beta_no_latent <- extract_best_betas(
  list(results_no_latent$lasso_model, results_no_latent$ridge_model, results_no_latent$enet_model),
  c("Lasso_Beta", "Ridge_Beta", "Enet_Beta")
)
print(head(feature_importance_no_latent))

# In[12]: Save Results without Latent ----
write.csv(feature_importance_no_latent, "drift_fs/csv/feature_importance_no_latent.csv", row.names = FALSE)
write.csv(beta_no_latent, "drift_fs/csv/beta_no_latent.csv", row.names = FALSE)

# save the models
saveRDS(results_no_latent, "drift_fs/models/results_no_latent.rds")

# In[13]: End ----


