#!/bin/bash
#SBATCH -p short                            # Partition to submit to
#SBATCH --nodes=2                           # Number of nodes
#SBATCH --ntasks-per-node=28                # Number of tasks per node (cores)
#SBATCH --time=0-02:00:00                   # Max wall time (D-HH:MM:SS)
#SBATCH --mail-type=ALL                     # Notifications for job done & fail
#SBATCH --mail-user=zaca2954@colorado.edu   # Email to notify
#SBATCH --output=job.%j.out                 # Output file (%j = job ID)
#SBATCH --error=job.%j.err                  # Error file (%j = job ID)
#SBATCH --job-name=rf_playground            # Job name

# Exit script if any command fails
set -e

# Logging some info for debugging
echo "Job started on $(hostname) at $(date)"
echo "Running with the following resources:"
echo " - Partition: $SLURM_JOB_PARTITION"
echo " - Nodes: $SLURM_JOB_NUM_NODES"
echo " - Tasks per node: $SLURM_NTASKS_PER_NODE"
echo " - Output: $SLURM_JOB_OUT"

# Activate Conda
source /Users/zaca2954/miniforge3/etc/profile.d/conda.sh
conda activate stanislawski_lab

# Run the pipeline
python /Users/zaca2954/stanislawski_lab/drift_fs/rf_playground.py