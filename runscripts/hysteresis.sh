#!/bin/bash

set +x

BED="Data/Topography/pert_r_0.01_harmonics_1-10.dat"
SIF='./SRC/SIFs/Hysterisis_norestart.sif'               # Template SIF FILE


NT=3001                                 # Number of time step
dt=1                                    # size of timestep
TT=$((NT*dt-dt))                        # total time of simulation

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


for RUN in "observed_IC" "smoothBed_SS_IC"; do

  if [ ! -d "Synthetic/Hystersis/${RUN}" ]; then
    mkdir Synthetic/Hystersis/${RUN}
  fi

  if [ ! -e "Synthetic/Hystersis/${RUN}/mesh" ]; then
    # Execute the .SIF file via "ElmerSolver"
    docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                     bash Mesh/makemsh.sh Synthetic/Hystersis/${RUN}/mesh"
  fi
done

for OFFSET in $(seq -w 2.40 0.001 2.41);do
  echo
  echo "--------------------------------------------------------------------------"
  echo "% Running Observed_IC with ${OFFSET} offset"
  echo "--------------------------------------------------------------------------"
  echo

  RUN="observed_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"
  EXP='observed_ic'
  BED='hystersis'
  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
       s#^\$EXP = [^ ]*#\$EXP = "'"${EXP}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' ./SRC/SIFs/Hysterisis_norestart.sif > "./SRC/SIFs/${RUN}.sif"

  echo "./SRC/SIFs/${RUN}.sif"  >> Inputs.txt

  # # Execute the .SIF file via "ElmerSolver"
  # docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
  #                                 ElmerSolver ./SRC/SIFs/${RUN}.sif \
  #                                 | tee ./logs/Hystersis/Observed_IC/${RUN}.log"

  # Clean the boundary data and convert from .dat to .nc
  echo python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/observed_ic/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/observed_ic/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp >> Outputs.txt

  # Remove the edited SIF to reduce clutter
  # rm ./SRC/SIFs/${RUN}.sif


  echo
  echo "--------------------------------------------------------------------------"
  echo "% Running SmoothBed_SS_IC with ${OFFSET} offset"
  echo "--------------------------------------------------------------------------"
  echo

  RUN="smoothbed_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"
  EXP='smoothbed_ss_ic'
  BED='hystersis'

  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
       s#^\$EXP = [^ ]*#\$EXP = "'"${EXP}"'"#;
       s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' ./SRC/SIFs/Hysterisis_restart.sif > "./SRC/SIFs/${RUN}.sif"

  echo "./SRC/SIFs/${RUN}.sif"  >> Inputs.txt

  # # Execute the .SIF file via "ElmerSolver"
  # docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
  #                                 ElmerSolver ./SRC/SIFs/${RUN}.sif \
  #                                 | tee ./logs/Hystersis/SmoothBed_SS_IC/${RUN}.log"

  # Clean the boundary data and convert from .dat to .nc
  echo python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/smoothbed_ss_ic/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/smoothbed_ss_ic/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp >> Outputs.txt

  # Remove the edited SIF to reduce clutter
  # rm ./SRC/SIFs/${RUN}.sif
done
