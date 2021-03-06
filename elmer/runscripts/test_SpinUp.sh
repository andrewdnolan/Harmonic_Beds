#!/bin/bash
#SBATCH --job-name="forgot line 0"                 # base job name for the array
#SBATCH --mem=200                                  # maximum 500M per job
#SBATCH --time=0:30:00                             # maximum walltime per job
#SBATCH --mail-type=ALL                            # send all mail (way to much)
#SBATCH --mail-user=andrew.d.nolan@maine.edu       # email to spend updates too
#SBATCH --output=logs/k=0.out                      # standard output
#SBATCH --error=logs/k=0.err                       # standard error
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
SIF=$(  sed -n "1p" Inputs.txt)
# Get the corresponding python call to clean surface boundary data
CLEAN=$(sed -n "1p" Outputs.txt)

# Execute the .sif file
ElmerSolver $SIF > logs/${SIF##*/}.log

# Clean the data using the `dat2h5.py` script
$CLEAN
