#!/bin/bash

set +x

BED="Data/Topography/pert_R_0.01_harmonics_1-10.dat"
SIF='./SRC/SIFs/Hysterisis_norestart.sif'               # Template SIF FILE


NT=1001                                 # Number of time step
dt=2                                    # size of timestep
TT=$((NT*dt))                           # total time of simulation

if [ ! -d "Synthetic/Hystersis" ]; then
  mkdir Synthetic/Hystersis
fi

# perturb the bed with first 10 harmonics of the series
# (i.e. evaluate the series from 1 to 10)
python3 ./SRC/utils/make_bed.py \
        -B Data/Topography/REF_BedTopo.dat \
        -O $BED \
        -H 215.0 \
        -N 10    \
        -R 0.01  \
        --sum


for RUN in "Observed_IC" "SmoothBed_SS_IC"; do

  if [ ! -d "Synthetic/Hystersis/${RUN}" ]; then
    mkdir Synthetic/Hystersis/${RUN}
  fi

  if [ ! -e "Synthetic/Hystersis/${RUN}/mesh" ]; then
    # Execute the .SIF file via "ElmerSolver"
    docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                     bash Mesh/makemsh.sh Synthetic/Hystersis/${RUN}/mesh"
  fi
done

for OFFSET in $(seq -w 2.35 0.01 2.45); do
  echo
  echo "--------------------------------------------------------------------------"
  echo "% Running Observed_IC with ${OFFSET} offset"
  echo "--------------------------------------------------------------------------"
  echo

  RUN="LK_PRE_${TT}a_MB_${OFFSET}_OFF"
  EXP='Observed_IC'
  BED='Hystersis'
  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
       s#^\$EXP = [^ ]*#\$EXP = "'"${EXP}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' ./SRC/SIFs/Hysterisis_norestart.sif > "./SRC/SIFs/${RUN}.sif"

  # Execute the .SIF file via "ElmerSolver"
  docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                  ElmerSolver ./SRC/SIFs/${RUN}.sif \
                                  | tee ./logs/Hystersis/Observed_IC/${RUN}.log"

  # Clean the boundary data and convert from .dat to .nc
  python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/Observed_IC/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/Observed_IC/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp

  # Remove the edited SIF to reduce clutter
  rm ./SRC/SIFs/${RUN}.sif


  echo
  echo "--------------------------------------------------------------------------"
  echo "% Running SmoothBed_SS_IC with ${OFFSET} offset"
  echo "--------------------------------------------------------------------------"
  echo

  RUN="LK_PRE_${TT}a_MB_${OFFSET}_OFF"
  EXP='SmoothBed_SS_IC'
  BED='Hystersis'
  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
       s#^\$EXP = [^ ]*#\$EXP = "'"${EXP}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' ./SRC/SIFs/Hysterisis_restart.sif > "./SRC/SIFs/${RUN}.sif"

  # Execute the .SIF file via "ElmerSolver"
  docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                  ElmerSolver ./SRC/SIFs/${RUN}.sif \
                                  | tee ./logs/Hystersis/SmoothBed_SS_IC/${RUN}.log"

  # Clean the boundary data and convert from .dat to .nc
  python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/SmoothBed_SS_IC/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/SmoothBed_SS_IC/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp

  # Remove the edited SIF to reduce clutter
  rm ./SRC/SIFs/${RUN}.sif
done
