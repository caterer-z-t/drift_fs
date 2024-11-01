# In[1]: Import libraries ----

rm(list = ls())

library(ggplot2)
library(reshape2)
library(dplyr)

# In[2]: Import data ----
base_path <- "/Users/zc/Library/CloudStorage/OneDrive-TheUniversityofColoradoDenver/Stanislawski_Lab/"
file_paths <- list(
    importance_latent = "drift_fs/csv/feature_importance_latent.csv",
    importance_no_latent = "drift_fs/csv/feature_importance_no_latent.csv",
    beta_latent = "drift_fs/csv/beta_latent.csv",
    beta_no_latent = "drift_fs/csv/beta_no_latent.csv"
)

# Read all data into a list
data_list <- lapply(paste0(base_path, file_paths), read.csv)

# In[3]: Data Manipulation ----
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

# Calculate importance and beta for latent and non-latent
importance_df_latent <- calculate_importance(data_list$importance_latent)
importance_df_no_latent <- calculate_importance(data_list$importance_no_latent)

beta_latent <- calculate_beta(data_list$beta_latent)
beta_no_latent <- calculate_beta(data_list$beta_no_latent)

# Filter out the middle 50% of beta values
filter_middle_50 <- function(df) {
    top_25 <- quantile(df$Beta, 0.9)
    bottom_25 <- quantile(df$Beta, 0.1)
    df %>% filter(Beta < bottom_25 | Beta > top_25)
}

beta_latent <- filter_middle_50(beta_latent)
beta_no_latent <- filter_middle_50(beta_no_latent)
print(head(beta_latent))
# Remove total columns
importance_df_latent <- select(importance_df_latent, -Importance)
importance_df_no_latent <- select(importance_df_no_latent, -Importance)
beta_latent <- select(beta_latent, -Beta)
beta_no_latent <- select(beta_no_latent, -Beta)

# In[4]: Plotting Feature Importance ----
plot_feature_importance <- function(df_latent, df_no_latent, title_prefix) {
    df_latent_melt <- melt(df_latent, id.vars = "Variable", variable.name = "Model", value.name = "Importance")
    df_no_latent_melt <- melt(df_no_latent, id.vars = "Variable", variable.name = "Model", value.name = "Importance")

    df_latent_melt$Type <- "With Latent Variables"
    df_no_latent_melt$Type <- "Without Latent Variables"

    combined <- rbind(df_latent_melt, df_no_latent_melt)

    p <- ggplot(combined, aes(x = reorder(Variable, Importance), y = Importance, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        facet_wrap(~Type) +
        theme_minimal() +
        labs(title = paste(title_prefix, "Feature Importance"), x = "Features", y = "Importance")
    ggsave(paste0("drift_fs/figures/feature_importance_", tolower(gsub(" ", "_", title_prefix)), ".png"), plot = p, dpi = 600, bg = "white")

    p_latent <- ggplot(df_latent_melt, aes(x = reorder(Variable, Importance), y = Importance, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        labs(title = paste(title_prefix, "Feature Importance with Latent Variables"), x = "Features", y = "Importance")
    ggsave(paste0("drift_fs/figures/feature_importance_latent", ".png"), plot = p_latent, dpi = 600, bg = "white")

    p_no_latent <- ggplot(df_no_latent_melt, aes(x = reorder(Variable, Importance), y = Importance, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        labs(title = paste(title_prefix, "Feature Importance without Latent Variables"), x = "Features", y = "Importance")
    ggsave(paste0("drift_fs/figures/feature_importance_no_latent", ".png"), plot = p_no_latent, dpi = 600, bg = "white")
}

plot_feature_importance(importance_df_latent, importance_df_no_latent, "Combined")

# In[5]: Plotting Beta Values ----
plot_beta_values <- function(df_latent, df_no_latent, title_prefix) {
    df_latent_melt <- melt(df_latent, id.vars = "Variable", variable.name = "Model", value.name = "Beta")
    df_no_latent_melt <- melt(df_no_latent, id.vars = "Variable", variable.name = "Model", value.name = "Beta")

    df_latent_melt$Type <- "With Latent Variables"
    df_no_latent_melt$Type <- "Without Latent Variables"

    combined <- rbind(df_latent_melt, df_no_latent_melt)

    p <- ggplot(combined, aes(x = reorder(Variable, Beta), y = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        facet_wrap(~Type) +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 2)) +
        labs(title = paste(title_prefix, "Beta Values"), x = "Features", y = "Beta Value")
    ggsave(paste0("drift_fs/figures/beta_", tolower(gsub(" ", "_", title_prefix)), ".png"), plot = p, dpi = 600, bg = "white")

    p_latent <- ggplot(df_latent_melt, aes(x = reorder(Variable, Beta), y = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 2)) +
        labs(title = paste(title_prefix, "Beta Values with Latent Variables"), x = "Features", y = "Beta Value")
    ggsave(paste0("drift_fs/figures/beta_latent", ".png"), plot = p_latent, dpi = 600, bg = "white")

    p_no_latent <- ggplot(df_no_latent_melt, aes(x = reorder(Variable, Beta), y = Beta, fill = Model)) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_flip() +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 2)) +
        labs(title = paste(title_prefix, "Beta Values without Latent Variables"), x = "Features", y = "Beta Value")
    ggsave(paste0("drift_fs/figures/beta_no_latent", ".png"), plot = p_no_latent, dpi = 600, bg = "white")
}

plot_beta_values(beta_latent, beta_no_latent, "Combined")
