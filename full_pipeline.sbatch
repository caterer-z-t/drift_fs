#!/bin/bash
#SBATCH --partition=amilan                  # Partition to submit to
#SBATCH --nodes=2                           # Number of nodes
#SBATCH --ntasks-per-node=28                # Number of tasks per node (cores)
#SBATCH --time=0-02:00:00                   # Max wall time (D-HH:MM:SS)
#SBATCH --mail-type=ALL                     # Notifications for job done & fail
#SBATCH --mail-user=zaca2954@colorado.edu   # Email to notify
#SBATCH --output=job.%j.out                 # Output file (%j = job ID)

# Exit script if any command fails
set -e

# Logging some info for debugging
echo "Job started on $(hostname) at $(date)"
echo "Running with the following resources:"
echo " - Partition: $SLURM_JOB_PARTITION"
echo " - Nodes: $SLURM_JOB_NUM_NODES"
echo " - Tasks per node: $SLURM_NTASKS_PER_NODE"
echo " - Output: $SLURM_JOB_OUT"

# Load necessary modules
module purge
module load anaconda
module load python/3.10.2
module load R/4.4.0

source .venv/bin/activate

# Activate the Conda environment
echo "Activating conda environment..."
conda activate stanislawski_lab

# Forcibly install necessary packages
pip install pandas numpy scikit-learn matplotlib seaborn tqdm matplotlib_venn pycaret

# Run Python script
echo "Running feature selection with rf_playground.py..."
python rf_playground.py

# Deactivate Conda environment
echo "Deactivating conda environment..."
conda deactivate

# Log completion
echo "Job finished at $(date)"
