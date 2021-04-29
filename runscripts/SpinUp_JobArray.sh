#!/bin/bash
#SBATCH --array=1-51                               # 50 jobs
#SBATCH --job-name=SpinUp_2000a_dt_1_dx_100_       # base job name for the array
#SBATCH --mem=75                                   # maximum 100M per job
#SBATCH --time=0:45:00                             # maximum walltime per job
#SBATCH --nodes=1                                  # Only one node is needed
#SBATCH --ntasks=1                                 # These are serial jobs
#SBATCH --mail-type=ALL                            # send all mail (way to much)
#SBATCH --mail-user=andrew.d.nolan@maine.edu       # email to spend updates too
#SBATCH --output=logs/SpinUp_dx_100_%A%a.out       # standard output
#SBATCH --error=logs/SpinUp_dx_100_%A%a.err        # standard error
# in the previous two lines %A" is replaced by jobID and "%a" with the array index

###############################################################################
#######################            Load ENV             #######################
###############################################################################
# Load Elmer
module load gcc/9.3.0
module load elmerfem/9.0

# Load python 3
module load python/3.6

# Creating virtual environments inside of your jobs
virtualenv --no-download $SLURM_TMPDIR/env_$SLURM_ARRAY_TASK_ID
source $SLURM_TMPDIR/env_$SLURM_ARRAY_TASK_ID/bin/activate

pip install --no-index --upgrade pip
pip install --no-index -r $HOME/requirements.txt
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
