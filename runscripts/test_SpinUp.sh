#!/bin/bash
#SBATCH --job-name="forgot line 22"                # base job name for the array
#SBATCH --mem=300                                  # maximum 500M per job
#SBATCH --time=4:00:00                             # maximum walltime per job
#SBATCH --mail-type=ALL                            # send all mail (way to much)
#SBATCH --mail-user=andrew.d.nolan@maine.edu       # email to spend updates too
# in the previous two lines %A" is replaced by jobID and "%a" with the array index

###############################################################################
#######################            Load ENV             #######################
###############################################################################
# Load Elmer
module load gcc/9.3.0
module load elmerfem/9.0

# Load python 3
#module load python/3.6

# Creating virtual environments inside of your jobs
virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate

pip install --no-index --upgrade pip
pip install --no-index -r $HOME/requirements.txt
###############################################################################

# Get the fp to a .sif file
SIF=$(  sed -n "22p" Inputs.txt)
# Get the corresponding python call to clean surface boundary data
CLEAN=$(sed -n "22p" Outputs.txt)

# Execute the .sif file
ElmerSolver $SIF > logs/${SIF##*/}.log

# Clean the data using the `dat2h5.py` script
$CLEAN