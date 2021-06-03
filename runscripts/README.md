# Run scripts

Documentation for each of the `bash` run scripts used to conduct the model runs.

__Note__: All run scripts are configured for running on remote computing resources
that uses a `SLURM` job scheduler. Therefore the run scripts don't actually execute
the `.sif`s, but aggregate all the commands to executed which are then submitted
to the `SLURM` scheduler.

## `SpinUp_JobArray.sh`  
Submit a `SLURM` [job array](https://crc.ku.edu/hpc/how-to/arrays) to scheduler.

## `runSpinUp.sh`
Run a mass balance grid search to find synthetic glacier steady state (SS) configuration.

## `runHarmonics_p1.sh`
Run a mass balance grid for the bed perturbed by each harmonic to find SS configuration.

## `runHarmonics_p2.sh`
Run the pseudo surge for the bed perturbed by each harmonic. 
