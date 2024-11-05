#!/bin/bash

# 1. Activate the virtual environment
conda activate stanislawski_lab

# 2. extract the data from the raw data files
Rscript read_rdata.R

# 3. Preprocess the data
python preprocess_data.py

# 4. Caret analysis
Rscript caret_analysis.R

# 5. figure generation
Rscript figure_playground.R