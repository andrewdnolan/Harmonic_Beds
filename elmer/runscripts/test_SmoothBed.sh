#!/bin/bash

TT=1500                                 # total time of simulation
SIF='./SRC/SIFs/Prognostic_SpinUp.sif'  # Template SIF FILE
BED='Smoothed_Test'                     # Mesh DB for the given bed config


for dx in 100 200; do
  dt=$(($dx/100))      # Number of time step
  NT=$((TT/dt+dt))      # size of timestep

  bedfile="./Data/Topography/SMOOTH_BedTopo.dat"

  end=$(awk 'END {print $1}'   $bedfile)
   Nx=$(awk -v L=$end -v dx=$dx 'BEGIN {OFMT = "%.0f"; print (L/dx)}')

  MESH_DB=mesh_dx${dx}

  if [ ! -d "Synthetic/${BED}/${MESH_DB}" ]; then
    docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                        bash ./Mesh/makemsh.sh ./Synthetic/${BED}/${MESH_DB} ${dx}"
    # Elmer .dat files folders
    mkdir "./Synthetic/${BED}/SaveData"
    # folder for VTU files
    mkdir "./Synthetic/${BED}/VTU"
    # folder for .nc files
    mkdir "./Synthetic/${BED}/hdf5"
  fi

  for OFFSET in $(seq -w 2.50 0.01 2.70); do

    # Model RUN identifier
    RUN="smoothtest_${TT}a_dt_${dt}_dx_${dx}_mb_${OFFSET}_off"

    # Update the .SIF FILE with the model run specifc params
    sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
         s#^$dt = [^ ]*#$dt = '"${dt}"'#;
         s#<DX>#'"$dx"'#;
         s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
         s#^\$BED = [^ ]*#\$BED = "'"${BED}"'"#;
         s#^$offset = [^ ]*#\$offset = '"${OFFSET}"'#;' "$SIF" > "./SRC/SIFs/${RUN}.sif"

    # echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt
    # Execute the .SIF file via "ElmerSolver"
    docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                     ElmerSolver ./SRC/SIFs/${RUN}.sif \
                                    | tee ./logs/Exp_01_elevation_dependent/${RUN}.log"

    # # Clean the boundary data and convert from .dat to .nc
    python3 ./SRC/utils/dat2h5.py \
            ./Synthetic/${BED}/SaveData/${RUN}.dat \
            -out_dir ./Synthetic/${BED}/hdf5 \
            -Nx $(($Nx+1)) \
            -dt $dt \
            -offset $OFFSET \
            -SpinUp

    # Remove the edited SIF to reduce clutter
    rm ./SRC/SIFs/${RUN}.sif

  done
done

# # After the full grid search of parameters lets make a plot showing  the convergence
# python SRC/plot_convergence.py ./Synthetic/Exp_01_elevation_dependent/hdf5
