# In[1]: Import libraries ----

rm(list = ls())

library(ggplot2)
library(reshape2)
library(tidyr)
library(scales)
library(dplyr)
library(VennDiagram)
library(viridis)

# In[2]: Import data ----
base_path <- "/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/"

# File paths
file_paths <- list(
    # latent data, contains all features including clinical and genus
    latent_beta = "drift_fs/csv/latent_beta.csv",
    latent_feature_importance = "drift_fs/csv/latent_feature_importance.csv",
    latent_metrics = "drift_fs/csv/latent_metrics.csv",

    # no genus data, contains only clinical features
    latent_no_genus_beta = "drift_fs/csv/latent_no_genus_beta.csv",
    latent_no_genus_feature_importance = "drift_fs/csv/latent_no_genus_feature_importance.csv",
    latent_no_genus_metrics = "drift_fs/csv/latent_no_genus_metrics.csv",
    
    # contains only the minimal latent and genus features
    minimal_latent_beta = "drift_fs/csv/minimal_latent_beta.csv",
    minimal_latent_feature_importance = "drift_fs/csv/minimal_latent_feature_importance.csv",
    minimal_latent_metrics = "drift_fs/csv/minimal_latent_metrics.csv",
    
    # contains only the minimal latent features
    minimal_no_genus_beta = "drift_fs/csv/minimal_no_genus_beta.csv",
    minimal_no_genus_feature_importance = "drift_fs/csv/minimal_no_genus_feature_importance.csv",
    minimal_no_genus_metrics = "drift_fs/csv/minimal_no_genus_metrics.csv",
    
    # contains only the genus features
    no_latent_beta = "drift_fs/csv/no_latent_beta.csv",
    no_latent_feature_importance = "drift_fs/csv/no_latent_feature_importance.csv",
    no_latent_metrics = "drift_fs/csv/no_latent_metrics.csv"
)

# Read all data into a named list
data_list <- lapply(file_paths, function(path) read.csv(paste0(base_path, path)))

# Name the list elements
names(data_list) <- names(file_paths)

# In[3]: Old Functions and Code ----

calculate_importance <- function(df) {
    df %>%
        # get a importance column which is a sum of the other columns
        # which are not the variable column
        mutate(Importance = rowSums(select(., -Variable), na.rm = TRUE)) %>%
        # arrange the data in descending order of importance
        arrange(desc(Importance)) %>%
        # select only the top 20 rows

        head(20)
}

# Function to calculate beta values
calculate_beta <- function(df) {
    df %>%
        mutate(Beta = rowSums(select(., -Variable), na.rm = TRUE)) %>%
        arrange(desc(Beta))
}

# Filter out the middle 50% of beta values
filter_middle_50 <- function(df) {
    top_25 <- quantile(df$Beta, 0.95)
    bottom_25 <- quantile(df$Beta, 0.05)
    df %>% filter(Beta < bottom_25 | Beta > top_25)
}

# Simplified plotting function for debugging
plot_feature_importance_single <- function(df_latent, save_image = FALSE, filename) {
    # Reshape the dataframe
    df_latent_melt <- melt(df_latent, id.vars = "Variable", variable.name = "Model", value.name = "Importance")

    # Plot without saving
    p <- ggplot(df_latent_melt, aes(x = reorder(Variable, Importance), y = Importance, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        labs(title = "Feature Importance with Latent Variables", x = "Features", y = "Importance")

    # Print the plot to debug
    print(p)

    # Save the plot if required
    if (save_image) {
        ggsave(paste0("drift_fs/figures/", filename), plot = p, dpi = 600, bg = "white")
    }
}

# Debugging combined plot function
plot_feature_importance_combined_debug <- function(df_latent, df_no_latent, save_image = FALSE, filename) {
    # Reshape both dataframes
    df_latent_melt <- melt(df_latent, id.vars = "Variable", variable.name = "Model", value.name = "Importance")
    df_no_latent_melt <- melt(df_no_latent, id.vars = "Variable", variable.name = "Model", value.name = "Importance")

    # Add type identifiers
    df_latent_melt$Type <- "With Latent Variables"
    df_no_latent_melt$Type <- "Without Latent Variables"

    # Combine the data
    combined <- rbind(df_latent_melt, df_no_latent_melt)

    # Create the combined plot
    p <- ggplot(combined, aes(x = reorder(Variable, Importance), y = Importance, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        facet_wrap(~Type) +
        theme_minimal() +
        labs(title = "Combined Feature Importance", x = "Features", y = "Importance")

    # Print the plot to debug
    print(p)

    # Save the plot if required
    if (save_image) {
        ggsave(paste0("drift_fs/figures/", filename), plot = p, dpi = 600, bg = "white")
    }
}

plot_beta_values_individual <- function(dataframe, save_image = FALSE, filename) {
    # Reshape the dataframe
    df_melt <- melt(dataframe, id.vars = "Variable", variable.name = "Model", value.name = "Beta")

    # Plot without saving
    p <- ggplot(df_melt, aes(x = reorder(Variable, Beta), y = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        labs(title = "Beta Values", x = "Features", y = "Beta")

    # Print the plot to debug
    print(p)

    # Save the plot if required
    if (save_image) {
        ggsave(paste0("drift_fs/figures/", filename), plot = p, dpi = 600, bg = "white")
    }
}

plot_beta_values_combines <- function(df_latent, df_no_latent, save_image = FALSE, filename){
    # Reshape the dataframe
    df_latent_melt <- melt(df_latent, id.vars = "Variable", variable.name = "Model", value.name = "Beta")
    df_no_latent_melt <- melt(df_no_latent, id.vars = "Variable", variable.name = "Model", value.name = "Beta")

    # Add type identifiers
    df_latent_melt$Type <- "With Latent Variables"
    df_no_latent_melt$Type <- "Without Latent Variables"

    # Combine the data
    combined <- rbind(df_latent_melt, df_no_latent_melt)

    # Create the combined plot
    p <- ggplot(combined, aes(x = reorder(Variable, Beta), y = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        facet_wrap(~Type) +
        theme_minimal() +
        labs(title = "Combined Beta Values", x = "Features", y = "Beta")

    # Print the plot to debug
    print(p)

    # Save the plot if required
    if (save_image) {
        ggsave(paste0("drift_fs/figures/", filename), plot = p, dpi = 600, bg = "white")
    }
}
# Calculate importance and beta for latent and non-latent
importance_df_latent <- calculate_importance(data_list$importance_latent)
importance_df_no_latent <- calculate_importance(data_list$importance_no_latent)

beta_latent <- calculate_beta(data_list$beta_latent)
beta_no_latent <- calculate_beta(data_list$beta_no_latent)

beta_latent <- filter_middle_50(beta_latent)
beta_no_latent <- filter_middle_50(beta_no_latent)

# Remove total columns
importance_df_latent <- select(importance_df_latent, -Importance)
importance_df_no_latent <- select(importance_df_no_latent, -Importance)
beta_latent <- select(beta_latent, -Beta)
beta_no_latent <- select(beta_no_latent, -Beta)

print(head(importance_df_latent))
print(head(importance_df_no_latent))

# Call the simplified function with importance_df_latent
# Correct function call
plot_feature_importance_single(importance_df_latent, save_image = TRUE, filename = "feature_importance_latent.png")
plot_feature_importance_single(importance_df_no_latent, save_image = TRUE, filename = "feature_importance_no_latent.png")

# Call the combined function with both dataframes
plot_feature_importance_combined_debug(importance_df_latent, importance_df_no_latent, save_image = TRUE, filename = "feature_importance_combined.png")

plot_beta_values_individual(beta_latent, save_image = TRUE, filename = "beta_latent.png")
plot_beta_values_individual(beta_no_latent, save_image = TRUE, filename = "beta_no_latent.png")

plot_beta_values_combines(beta_latent, beta_no_latent, save_image = TRUE, filename = "beta_combined.png")

# In[4]: New Functions and Code ----

# select the top 20 features from the feature importance dataframe
# for each model--each model has a column in the dataframe
# Function to get top N important features for a given model
get_top_n_features <- function(feature_importance, model_importance_column, n = 20) {
    feature_importance %>%
        select(Variable, all_of(model_importance_column)) %>%
        arrange(desc(get(model_importance_column))) %>%
        head(n)
}

# Function to get top N important features for each model
get_top_n_features_all_models <- function(feature_importance, n = 20) {
    # Identify all columns that end with "_Importance"
    importance_columns <- names(feature_importance)[grepl("_Importance$", names(feature_importance))]

    # Initialize a list to store results for each model
    top_features_list <- list()

    # Loop through each importance column and get top N features
    for (column in importance_columns) {
        model_name <- gsub("_Importance", "", column) # Extract model name
        top_features <- get_top_n_features(feature_importance, column, n)
        top_features_list[[model_name]] <- top_features
    }

    return(top_features_list)
}

# Function to get top N important features for a given model
get_top_n_features <- function(feature_importance, model_importance_column, n = 20) {
    feature_importance %>%
        select(Variable, all_of(model_importance_column)) %>%
        arrange(desc(get(model_importance_column))) %>%
        head(n)
}

# Function to get top N important features for each model
get_top_n_features_all_models <- function(feature_importance, n = 20) {
    # Identify all columns that end with "_Importance"
    importance_columns <- names(feature_importance)[grepl("_Importance$", names(feature_importance))]

    # Initialize a list to store results for each model
    top_features_list <- list()

    # Loop through each importance column and get top N features
    for (column in importance_columns) {
        model_name <- gsub("_Importance", "", column) # Extract model name
        top_features <- get_top_n_features(feature_importance, column, n)
        top_features_list[[model_name]] <- top_features
    }

    return(top_features_list)
}

# Function to plot Venn diagram for top features
plot_venn_diagram <- function(feature_sets, colors = NULL, figurename = "venn_diagram.png", output_dir = "drift_fs/figures/") {
    if (is.null(colors)) {
        colors <- viridis(length(feature_sets))
    }

    venn.plot <- venn.diagram(
        x = feature_sets,
        category.names = names(feature_sets),
        filename = NULL, # Plot directly to the object
        output = TRUE,
        col = "transparent",
        fill = colors,
        alpha = 0.3,
        cex = 1.5,
        cat.cex = 1.2,
        cat.pos = 0,
        margin = 0.1
    )

    ggsave(paste0(output_dir, figurename), plot = venn.plot, dpi = 600, bg = "white")
}


plot_importance_or_beta <- function(data, value_column, plot_title, y_label, figurename, palette = "viridis") {
    long_format <- data %>%
        pivot_longer(
            cols = ends_with(value_column),
            names_to = "Model",
            values_to = value_column
        )

    ggplot(long_format, aes(y = reorder(Variable, !!sym(value_column)), x = !!sym(value_column), fill = Model)) +
        geom_bar(stat = "identity", position = position_dodge(width = 0.9), width = 0.7) +
        scale_fill_viridis_d(option = palette) +
        labs(
            title = plot_title,
            x = paste(value_column, "Score"),
            y = y_label
        ) +
        theme_minimal() +
        theme(
            axis.text.y = element_text(size = 5), # Adjust text size
            axis.title.y = element_text(vjust = 1)
        ) +
        scale_y_discrete(expand = expansion(mult = c(0.1, 0.2))) # Add padding between features

    ggsave(paste0("drift_fs/figures/", figurename), dpi = 600, bg = "white")
}

# Function to plot Beta values for top features by model
plot_beta_values <- function(beta_top_features, figurename = "beta_values.png") {
    beta_long_format <- beta_top_features %>%
        pivot_longer(
            cols = ends_with("_Beta"),
            names_to = "Model",
            values_to = "Beta"
        )

    ggplot(beta_long_format, aes(y = reorder(Variable, Beta), x = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = position_dodge(width = 0.9), width = 0.7) +
        scale_fill_viridis_d() +
        labs(
            title = "Top Feature Beta Values by Model",
            x = "Beta Value",
            y = "Feature"
        ) +
        theme_minimal() +
        theme(
            axis.text.y = element_text(size = 5), # Adjust text size
            axis.title.y = element_text(vjust = 1)
        ) +
        scale_y_discrete(expand = expansion(mult = c(0.1, 0.2))) # Add padding between features
    ggsave(paste0("drift_fs/figures/", figurename), dpi = 600, bg = "white")
}

# Function to process data and generate plots for a dataset
process_and_plot_data <- function(data_list, dataset_name, n = 20) {
    beta <- data_list$beta
    feature_importance <- data_list$feature_importance
    metrics <- data_list$metrics

    # Get top N features for all models
    top_20_features <- get_top_n_features_all_models(feature_importance, n)

    # Create feature sets for Venn diagram
    feature_sets <- lapply(top_20_features, function(df) df$Variable)

    # Plot Venn diagram with dataset name included in the filename
    plot_venn_diagram(feature_sets, figurename = paste0(dataset_name, "_venn_diagram.png"))

    # Extract top features and sort by total importance
    all_top_features <- unique(unlist(feature_sets))
    filtered_feature_importance <- feature_importance %>%
        filter(Variable %in% all_top_features) %>%
        mutate(Total_Importance = rowSums(select(., ends_with("_Importance")), na.rm = TRUE)) %>%
        arrange(desc(Total_Importance))

    # Remove total importance column
    filtered_feature_importance <- select(filtered_feature_importance, -Total_Importance)

    # Plot feature importance with dataset name included in the filename
    plot_importance_or_beta(filtered_feature_importance, "Importance", "Top Feature Importance by Model", "Feature", paste0(dataset_name, "_feature_importance.png"))

    # Extract beta values for top features and ensure order matches
    beta_top_features <- beta %>%
        filter(Variable %in% all_top_features) %>%
        arrange(match(Variable, all_top_features))

    # Plot beta values with dataset name included in the filename
    plot_importance_or_beta(beta_top_features, "Beta", "Top Feature Beta Values by Model", "Feature", paste0(dataset_name, "_beta_values.png"))
}

# Apply the process_and_plot_data function to each dataset
dataset_list <- list(
    latent = list(
        beta = data_list$latent_beta,
        feature_importance = data_list$latent_feature_importance,
        metrics = data_list$latent_metrics
    ),
    latent_no_genus = list(
        beta = data_list$latent_no_genus_beta,
        feature_importance = data_list$latent_no_genus_feature_importance,
        metrics = data_list$latent_no_genus_metrics
    ),
    minimal_latent = list(
        beta = data_list$minimal_latent_beta,
        feature_importance = data_list$minimal_latent_feature_importance,
        metrics = data_list$minimal_latent_metrics
    ),
    minimal_no_genus = list(
        beta = data_list$minimal_no_genus_beta,
        feature_importance = data_list$minimal_no_genus_feature_importance,
        metrics = data_list$minimal_no_genus_metrics
    ),
    no_latent = list(
        beta = data_list$no_latent_beta,
        feature_importance = data_list$no_latent_feature_importance,
        metrics = data_list$no_latent_metrics
    )
)

# Apply the function to each dataset in the list
lapply(names(dataset_list), function(dataset_name) {
    process_and_plot_data(dataset_list[[dataset_name]], dataset_name)
})



# Assuming dataset_list$latent$metrics contains the performance metrics for each model and dataset type
# Reshape the data into long format
metrics_long <- dataset_list$latent$metrics %>%
    pivot_longer(
        cols = c("R2", "MAE", "RMSE"),
        names_to = "Metric",
        values_to = "Value"
    )

# Reorder the factor levels so that 'Train' comes before 'Test' and metrics are grouped
metrics_long$DataType <- factor(metrics_long$DataType, levels = c("Train", "Test"))
metrics_long$Metric <- factor(metrics_long$Metric, levels = c("R2", "MAE", "RMSE"))

# Plot the grouped metrics for each model with Viridis color theme
ggplot(metrics_long, aes(x = Model, y = Value, fill = Metric)) +
    geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    facet_wrap(~Metric, scales = "free_y", ncol = 1) + # One panel per metric (R2, MAE, RMSE)
    labs(
        title = "Model Performance Metrics (R², MAE, RMSE)",
        x = "Model",
        y = "Metric Value",
        fill = "Metric"
    ) +
    scale_fill_viridis(discrete = TRUE) + # Apply Viridis color palette
    theme_minimal() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1), # Rotate model names for better readability
        axis.text.y = element_text(size = 10), # Adjust y-axis text size
        strip.text = element_text(size = 12), # Adjust facet label size
        legend.position = "top" # Place the legend on top
    )

