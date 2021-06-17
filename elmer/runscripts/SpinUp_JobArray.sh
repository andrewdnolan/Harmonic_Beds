#!/bin/bash
#SBATCH --array=1-16                               # 16 jobs that run 20 at a time
#SBATCH --job-name=Pseudo_10a_dt_1_dx_50_          # base job name for the array
#SBATCH --mem-per-cpu=200                          # maximum 200M per job
#SBATCH --time=1:00:00                             # maximum walltime per job
#SBATCH --nodes=1                                  # Only one node is needed
#SBATCH --ntasks=1                                 # These are serial jobs
#SBATCH --mail-type=ALL                            # send all mail (way to much)
#SBATCH --mail-user=andrew.d.nolan@maine.edu       # email to spend updates too
#SBATCH --output=logs/Pseudo_dx_50_%A_%a.out       # standard output
#SBATCH --error=logs/Pseudo_dx_50_%A_%a.err        # standard error
# in the previous two lines %A" is replaced by jobID and "%a" with the array index

###############################################################################
#######################            Load ENV             #######################
###############################################################################
# Load Elmer
module load gcc/9.3.0
module load elmerfem/9.0

# Load python 3
module load python/3.6

# Lazy way
module load scipy-stack
source $HOME/py4elmer/bin/activate
###############################################################################

# Get the fp to a .sif file
SIF=$(  sed -n "${SLURM_ARRAY_TASK_ID}p" Inputs.txt)
# Get the corresponding python call to clean surface boundary data
CLEAN=$(sed -n "${SLURM_ARRAY_TASK_ID}p" Outputs.txt)

# Execute the .sif file
ElmerSolver $SIF > logs/${SIF##*/}.log

# Clean the data using the `dat2h5.py` script
$CLEAN

# Get rid of the sif file to reduce clutter
rm $SIF
