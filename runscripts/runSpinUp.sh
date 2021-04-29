#!/bin/bash

SECONDS=0

NT=2001                                 # Number of time step
dt=1                                    # size of timestep
TT=$((NT*dt-dt))                        # total time of simulation
SIF='./SRC/SIFs/Prognostic_SpinUp.sif'  # Template SIF FILE
BED='Farinotti_smooth'                  # Mesh DB for the given bed config

for OFFSET in $(seq -w 2.00 0.01 2.50);do
#for OFFSET in $(seq -w 2.07 0.01 2.07); do
  # Model RUN identifier
  RUN="LK_PRE_${TT}a_dt_${dt}_dx_100_MB_${OFFSET}_OFF"

  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' "$SIF" > "./SRC/SIFs/${RUN}.sif"

  echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt
  # # Execute the .SIF file via "ElmerSolver"
  # docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
  #                                   ElmerSolver ./SRC/SIFs/${RUN}.sif \
  #                                 | tee ./logs/Exp_01_elevation_dependent/${RUN}.log"
  #
  # # Clean the boundary data and convert from .dat to .nc
  echo python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/Exp_01_elevation_dependent/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/Exp_01_elevation_dependent/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp  >> Outputs.txt
  #
  # # Remove the edited SIF to reduce clutter
  # rm ./SRC/SIFs/${RUN}.sif
done

#
# ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
#
# echo $ELAPSED

# # After the full grid search of parameters lets make a plot showing  the convergence
# python SRC/plot_convergence.py ./Synthetic/Exp_01_elevation_dependent/hdf5
