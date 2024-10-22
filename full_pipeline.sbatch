#!bin/bash

#SBATCH --partition=amilan
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=04:00:00

# loading the necessary modules and packages
module load anaconda
module load python
module load R/4.4.0

# activating necessary venv containing all the necessary libraries and imports
conda activate stanislawski_lab

# preparing the datafiles
Rscript read_rdata.R

# conduct the randomforest
python rf.py
