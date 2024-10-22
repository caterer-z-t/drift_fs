###############################################
###
###               Imports
###
###############################################

library(tools)

###############################################
###
###               Functions
###
###############################################

# Function to load RData file into a new environment and return the environment
load_rdata <- function(file_path) {
    if (file_ext(file_path) == "RData") {
        # Create a new environment to load the RData file into
        env <- new.env()
        load(file_path, envir = env)  # Load the RData file into the new environment
        message("RData file loaded successfully.")
        
        # Return the environment for further inspection
        return(env)
        
    } else {
        stop("The file is not an RData file.")
    }
}

# Function to automatically save all data frames/matrices in an environment as CSV files
save_env_to_csv <- function(env, output_dir) {
    # Ensure the output directory exists
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }
    
    # Loop through the objects in the environment
    for (obj_name in ls(envir = env)) {
        obj <- get(obj_name, envir = env)
        
        # Check if the object is a data frame or matrix
        if (is.data.frame(obj) || is.matrix(obj)) {
            file_path <- file.path(output_dir, paste0(obj_name, ".csv"))
            write.csv(obj, file = file_path)
            message(paste("Saved:", file_path))
        } else {
            message(paste("Skipping:", obj_name, "as it is not a data frame or matrix."))
        }
    }
}

###############################################
###
###               Beta Diversity Data
###
###############################################

# Define file paths and directories
base_file_path <- "/home/zaca2954/iq_bio/stanislawski_lab/stanislawski_lab_data/"
file_name <- "BetaDiversity_DMs.RData"
output_dir <- "/home/zaca2954/iq_bio/stanislawski_lab/output"  # Define output directory

# Load the RData file into a new environment
env <- load_rdata(file.path(base_file_path, file_name))

# Save all data frames/matrices to CSV files
save_env_to_csv(env, output_dir)

###############################################
###
###               Genus and Species Data
###
###############################################

# Load another RData file for taxa data and save to CSV
genus_tables <- '/home/zaca2954/iq_bio/stanislawski_lab/DRIFT2/Data/Clean16S/Genus_Sp_tables.RData'
env_taxa <- load_rdata(genus_tables)
save_env_to_csv(env_taxa, output_dir)
