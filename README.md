# drift_fs

## Overview
This project contains the main R script titled `2024_zc_analysis.R`. This script consolidates four individually developed files into a single, unified workflow for simplicity and to reflect their interdependencies. Each section of this file corresponds to one of the original files and their respective analyses. Below, you will find a walkthrough of each section, including the processes, resultant files, and analyses. 

To navigate this document, please refer to the [Table of Contents](#table-of-contents).

This project was conducted as part of the **Interdisciplinary Quantitative Biology Program** at the **BioFrontiers Institute, University of Colorado Boulder**, in collaboration with the **Stanislawski Lab** at the **University of Colorado Anschutz Department of Biomedical Informatics and Personalized Medicine**.

## Table of Contents
- [Essential Information Before Getting Started](#essential-information-before-getting-started)
  - [Necessary Libraries](#necessary-libraries)
  - [Necessary Datasets](#necessary-datasets)
- [Section Explanation: Reading and Converting R Data Files](#section-explanation-reading-and-converting-r-data-files)
  - [Dataset Information](#dataset-information)
  - [Function Information](#function-information)
  - [Final Output](#final-output)
- [Section Explanation: Data Processing](#section-explanation-data-processing)
  - [Dataset Information - Processing](#dataset-information---processing)
  - [Function Information - Processing](#function-information---processing)
  - [Final Output - Processing](#final-output---processing)
- [Section Explanation: Caret Analysis](#section-explanation-caret-analysis)
  - [Dataset Information - Analysis](#dataset-information---analysis)
  - [Function Information - Analysis](#function-information---analysis)
  - [Final Notes - Analysis](#final-notes---analysis)
- [Section Explanation: Figures](#section-explanation-figures)
  - [Dataset Information - Figures](#dataset-information---figures)
  - [Function Information - Figures](#function-information---figures)
  - [Final Notes](#final-notes)

## Essential Information Before Getting Started
Before running the analysis, ensure that the required libraries and datasets are available. Detailed explanations of the datasets are provided in subsequent sections, but this section provides a quick reference for essential resources.

This code is intended to be run on Alpine on your working directory calling the PetaLibrary for files. The structure of your working directory should consist of:

``` bash
drift_fs/
├── csv/
│   ├── processed_data/
│   ├── results/
│   └── unprocessed_data/
├── figures/
├── models/
└── 2024_zc_analysis.R
```

### Necessary Libraries
The following R libraries are required for this analysis. Install them using `install.packages()` if they are not already installed.

```r
library(tools)
library(readr)
library(reticulate)
library(caret)
library(caretEnsemble)
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
library(ggplot2)
library(reshape2)
library(scales)
library(VennDiagram)
library(viridis)
library(gridExtra)
library(plotly)
library(tidyplots)
library(tidyverse)
library(patchwork) 
library(ggvenn)
library(jsonlite)
library(maps)
library(sf)
```

## Necessary Datasets
The following datasets are integral to the analysis:

- `Genus_Sp_tables.RData`
- `merge_meta_methyl.csv`
- `DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv`
- `grs.diff_110324.csv`
- `path_abun_unstrat.tsv`

# Section Explanation: Reading and Converting R Data Files

This section of the code is designed to convert `RData` files into `CSV` files to enable further analysis in Python. While my native programming language is Python, the initial dataset is provided in `RData` format, which is not directly compatible with Python. Thus, this code serves as a one-time utility to transform the `RData` files into `CSV` files for subsequent use in Python-based analyses.

If you plan to continue the analysis entirely in R, the original `RData` files could be used directly. However, the subsequent sections of this script assume the data is in `CSV` format. Adapting this workflow for an R-only approach would require modifying the later code to work directly with the `RData` files.

## Dataset Information
- **`Genus_Sp_tables.RData`**: Contains genus and species-level data, including:
  - Counts
  - Relative abundance
  - CLR (Centered Log Ratio) transformed tables

## Function Information
1. **`load_rdata(file_path)`**  
   A utility function to load `RData` files into a new environment, returning the environment for inspection.

2. **`save_env_to_csv(env, output_dir)`**  
   Automates the process of saving all data frames and matrices from an `RData` environment into separate `CSV` files, named according to the objects in the environment.

## Final Output
The processed data from this section generates six new files:
- **`genus.clr.csv`**: Combines genus-level center log ratio dataset
- **`genus.count.csv`**: Combines genus-level count dataset
- **`genus.ra.csv`**: Combines genus-level relative abundance dataset
- **`sp.clr.csv`**: Combines species-level center log ratio dataset
- **`sp.count.csv`**: Combines species-level count dataset
- **`sp.ra.csv`**: Combines species-level relative abundance dataset


# Section Explanation: Data Processing

This section was originally developed with the intention of being used in Python. I even wrote the initial version of this code in Python. However, once I realized that `Caret` is better suited for R, I decided to streamline the workflow by rewriting the code in R. This transition proved highly beneficial as it allowed for easier updates and modifications throughout the project's progression.

The primary goal of this section is to focus the analysis on baseline datasets by:
- Removing redundant columns (e.g., time series information and unnecessary clinical data).
- Simplifying downstream analysis by consolidating microbiota and metadata into a single file.  

As a result, this script prepares the data for further regression analysis by streamlining and integrating relevant datasets.

## Dataset Information - Processing
The following datasets are processed in this section:
- **`grs.diff_110324.csv`**: Contains the updated prediction metric used in the regression model during the `Caret` analysis.
- **`genus.clr.csv`**: Contains genus-level taxa information, generated in the previous step.
- **`sp.clr.csv`**: Contains species-level taxa information, generated in the previous step.
- **`merge_meta_methyl.csv`**: Includes some clinical metadata.
- **`DRIFT_working_dataset_meta_deltas_filtered_05.21.2024.csv`**: Contains additional clinical metadata.

## Function Information - Processing
- **`make_new_columns()`**  
  Splits the `subject_id_timeseries` column into two new columns: `subject_id` and `timeseries`.

- **`filter_data()`**  
  Filters the dataset based on specific conditions (trivial functionality).

- **`merge_data()`**  
  Joins two datasets using a shared common feature. This function also removes and renames unnecessary columns generated during the join.

- **`remove_columns()`**  
  Removes specific columns from the dataset (trivial functionality).

- **`extract_columns()`**  
  Extracts columns based on a predefined list or specified pattern.

- **`py_run_string()` or `rename_columns_species_to_domain()`**  
  Highlights Python integration within R using the `reticulate` package. This function leverages Python code to rename column headers, converting them to the lowest taxonomic level provided.

## Final Output - Processing
The processed data from this section generates two new files:
- **`genus_latent.csv`**: Combines genus-level microbiota information with clinical metadata for the baseline dataset.
- **`species_latent.csv`**: Combines species-level microbiota information with clinical metadata for the baseline dataset.

These files serve as consolidated inputs for downstream analysis, ensuring both microbiota and clinical data are integrated and focused solely on the baseline dataset.

# Section Explanation: Caret Analysis

This section represents the core of my rotation project and the part where I dedicated most of my time. If you are rerunning the analysis, be prepared to spend significant time here as well. 

Initially, the scripts in this section were separate, standalone files, resulting in some overlap and repetition of functions. If given more time, I would have streamlined the workflow into a single, cohesive script. This improvement remains a future goal, and I will update this section once the code is fully optimized.

## Dataset Information - Analysis
The following datasets are utilized in this analysis:
- **`species_latent.csv`**: Contains species-level taxa information along with clinical metadata. Generated in the previous step.
- **`genus_latent.csv`**: Contains genus-level taxa information along with clinical metadata. Generated in the previous step.
- **`genus.ra.csv`**: Used to remove redundant columns.
- **`sp.ra.csv`**: Used to remove redundant columns.
- **`path_abun_unstrat.tsv`**: Used for pathway analysis.

## Function Information - Analysis
Below is a detailed explanation of the key functions used in this section:

- **`make_new_columns()`**  
  Refer to the "Function Information - Processing" section for details.

- **`filter_data()`**  
  Refer to the "Function Information - Processing" section for details.

- **`remove_columns()`**  
  Refer to the "Function Information - Processing" section for details.

- **`preprocess_data()`**  
  Utilizes the `Caret` package to impute missing values in the dataset based on a specified imputation method.

- **`process_data()`**  
  Cleans the dataset by removing specified columns and running the `preprocess_data()` function.

- **`train_all_models()`**  
  Specifies the parameters for the individual models used in the analysis, such as Lasso, Elastic Net, Ridge, and others.

- **`extract_importance_df()`**  
  Extracts the feature importance scores from the models after running the `Caret` analysis.

- **`combine_importances()`**  
  Combines the importance scores from individual models into a single DataFrame for easier analysis and visualization.

- **`extract_best_betas()`**  
  Extracts the beta values (coefficients) from regression models such as Lasso, Elastic Net, and Ridge after the analysis.

- **`replace_na()`**  
  Replaces missing values (`NA`) with `0` for simplicity. (Trivial functionality.)

- **`calculate_metrics()`**  
  Computes key performance metrics for the models on both training and testing datasets.

- **`train_and_save_models()`**  
  A comprehensive function that integrates most of the above functions. It runs the full analysis pipeline and saves all necessary outputs, including:
  - Model metrics
  - Feature importance scores
  - Trained model objects

## Final Notes - Analysis
This section not only performs the core machine learning analysis but also generates critical outputs required for interpretation and downstream work. While the current workflow contains some redundancies, it remains highly functional. Future updates will aim to streamline and consolidate these functions into a more efficient script.

# Section Explanation: Figures

This section was developed to create all the figures for this project. My undergraduate PI, Dr. Rahul Gomes, shared valuable advice: always keep all figures for a project, paper, or presentation in a single file. This approach ensures consistency and makes it easier to locate and modify individual figures when needed. While it may not be the most efficient method, it provides a reliable and organized structure.

This file contains the code for all figures generated programmatically for my presentation. Additional figures, such as those created using BioRender, were made manually. The script also includes rough functions to process and plot figures quickly, primarily for visualizing analysis results. However, these preliminary visualizations were not included in the final presentation.

## Dataset Information - Figures
The script utilizes multiple datasets, each containing metrics, feature importance scores, and beta coefficient files. These datasets are derived from the `Caret` analysis in the previous step and include the following categories:
- **Genus**  
- **Genus (No Redundant)**  
- **Genus (No Latent)**  
- **Pathway**  
- **Pathway (No Redundant)**  
- **Pathway (No Latent)**  
- **Species**  
- **Species (No Redundant)**  
- **Species (No Latent)**  

## Function Information - Figures

Below is a summary of the functions used to generate the figures:

- **`get_top_n_features()`**  
  Retrieves the top `n` features from a given dataset.

- **`get_top_n_features_all_models()`**  
  Extracts the top `n` features across all models for comparison.

- **`plot_venn_diagram()`**  
  Creates a Venn diagram to visualize feature overlap. (Trivial functionality.)

- **`plot_importance_or_beta()`**  
  Generates plots for feature importance or beta coefficients. (Trivial functionality.)

- **`plot_performance_metrics()`**  
  Creates visualizations for model performance metrics. (Trivial functionality.)

- **`process_and_plot_data()`**  
  Processes the specified datasets and saves the corresponding figures.

## Final Notes
This section provides a centralized approach for figure generation, ensuring all visualizations are accessible and editable within a single script. While some functions are preliminary and not optimized for polished outputs, they serve as useful tools for exploratory data visualization. Future improvements may involve refining these functions for broader use in presentations and publications.
