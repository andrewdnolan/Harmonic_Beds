#!/bin/bash

NT=501                              # Number of time step
dt=2                                # size of timestep
TT=$((NT*dt))                       # total time of simulation
SIF='./SIFs/Prognostic_SpinUp.sif'  # Template SIF FILE

# Since we have multiple flow lines and still working on tweaking them
# we will save that boundary files in specific directories which describe
# the flowline and type of simulation the data is from.
# DATA_FOLDER='LK_PRE_ST_full_SVR_mb'

for OFFSET in $(seq -w 0.00 0.10 2.51);do
#for OFFSET in $(seq -w 2.50 0.10 2.50);do

  # Model RUN identifier
  RUN="LK_PRE_${TT}a_MB_${OFFSET}_OFF"

  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' "$SIF" > "./SIFs/${RUN}.sif"

  # ElmerSolver the .SIF file
  docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; ElmerSolver SIFs/${RUN}.sif \
                                  | tee ./logs/Exp_01_elevation_dependent/${RUN}.log"

  #clean the boundary data and convert from .dat to .h5
  python3 ./SRC/dat2h5.py ./Synthetic/Exp_01_elevation_dependent/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/Exp_01_elevation_dependent/hdf5 -Nx 143

  # Remove the edited SIF to reduce clutter
  rm ./SIFs/${RUN}.sif
done

# After the full grid search of parameters lets make a plot showing  the convergence
python SRC/plot_convergence.py ./Synthetic/Exp_01_elevation_dependent/hdf5
