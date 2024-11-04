# Load libraries
library(caret)
library(randomForest)
library(iml)
library(fastshap)
library(ggplot2)

# Set up training control
train_control <- trainControl(method = "cv", number = 5) # 5-fold cross-validation

# Train the random forest model using caret
set.seed(123)
rf_model <- caret::train(
    Species ~ .,
    data = iris,
    method = "rf",
    trControl = train_control,
    importance = TRUE
)


# Extract the final model from caret
rf <- rf_model$finalModel

# Compute SHAP values for each feature in the dataset
set.seed(123)
shap_values <- fastshap::explain(rf, X = iris[, -5], pred_wrapper = predict, nsim = 10)

# Convert SHAP values to long format
shap_long <- as.data.frame(shap_values)
shap_long$Observation <- rep(1:nrow(iris), each = ncol(iris) - 1) # Repeat each observation ID for each feature
shap_long <- reshape2::melt(shap_long, id.vars = "Observation", variable.name = "Feature", value.name = "SHAP")

# Add feature values to shap_long by matching Observation and Feature
feature_values <- reshape2::melt(iris[, -5], variable.name = "Feature", value.name = "FeatureValue")
shap_long$FeatureValue <- feature_values$FeatureValue

# Beeswarm-like plot with ggplot2
ggplot(shap_long, aes(x = Feature, y = SHAP, color = FeatureValue)) +
    geom_jitter(width = 0.2, alpha = 0.7) +
    scale_color_gradient(low = "blue", high = "red") +
    theme_minimal() +
    labs(title = "Beeswarm Plot of SHAP Values", x = "Feature", y = "SHAP Value") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
