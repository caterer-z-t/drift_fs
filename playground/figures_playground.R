# In[1]: Import libraries ----

rm(list = ls())

library(ggplot2)
library(reshape2)
library(scales)
library(dplyr)

# In[2]: Import data ----
base_path <- "/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/"

# File paths
file_paths <- list(
    importance_latent = "drift_fs/csv/feature_importance_latent.csv",
    importance_no_latent = "drift_fs/csv/feature_importance_no_latent.csv",
    beta_latent = "drift_fs/csv/beta_latent.csv",
    beta_no_latent = "drift_fs/csv/beta_no_latent.csv"
)

# Read all data into a named list
data_list <- lapply(file_paths, function(path) read.csv(paste0(base_path, path)))

# Name the list elements
names(data_list) <- names(file_paths)

# Print the head of the specific dataset
print(head(data_list$importance_latent))
# In[3]: Functions ----

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
# In[4]: Data Manipulation ----

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
# In[5]: Plotting Feature Importance ----

# Call the simplified function with importance_df_latent
# Correct function call
plot_feature_importance_single(importance_df_latent, save_image = TRUE, filename = "feature_importance_latent.png")
plot_feature_importance_single(importance_df_no_latent, save_image = TRUE, filename = "feature_importance_no_latent.png")

# Call the combined function with both dataframes
plot_feature_importance_combined_debug(importance_df_latent, importance_df_no_latent, save_image = TRUE, filename = "feature_importance_combined.png")

# In[6]: Plotting Beta Values ----

plot_beta_values_individual(beta_latent, save_image = TRUE, filename = "beta_latent.png")
plot_beta_values_individual(beta_no_latent, save_image = TRUE, filename = "beta_no_latent.png")

plot_beta_values_combines(beta_latent, beta_no_latent, save_image = TRUE, filename = "beta_combined.png")
