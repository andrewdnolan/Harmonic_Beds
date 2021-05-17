#!/bin/bash

SECONDS=0

NT=2001                                 # Number of time step
dt=1                                    # size of timestep
dx=100                                  # Grid cell spacing
TT=$((NT*dt-dt))                        # total time of simulation
SIF='./SRC/SIFs/Prognostic_SpinUp.sif'  # Template SIF FILE
BED='farinotti_corrected'               # Mesh DB for the given bed config
EXP="exp_01_elevation_dependent"

for OFFSET in $(seq -w 1.90 0.01 2.10);do

  # Model RUN identifier
  RUN="LK_PRE_${TT}a_dt_${dt}_dx_100_MB_${OFFSET}_OFF"

  # Update the .SIF FILE with the model run specifc params
  sed "s#<NT>#"$NT"#g;
       s#<dt>#"$dt"#g;
       s#<DX>#"$dx"#g;
       s#<EXP>#"$EXP"#g;
       s#<BED>#"$BED"#g;
       s#<RUN>#"$RUN"#g;
       s#<OFFSET>#"$OFFSET"#g" "$SIF" > "./SRC/SIFs/${RUN}.sif"
  #    s#<BED_FP>#"$BED_FP"#g;


  echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt

  # # Execute the .SIF file via "ElmerSolver"
  # docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
  #                                   ElmerSolver ./SRC/SIFs/${RUN}.sif \
  #                                 | tee ./logs/Exp_01_elevation_dependent/${RUN}.log"

  # # Clean the boundary data and convert from .dat to .nc
  echo python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${BED}/exp_01_elevation_dependent/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${BED}/exp_01_elevation_dependent/hdf5 \
          -Nx 279 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp >> Outputs.txt
  #
  # # Remove the edited SIF to reduce clutter
  # rm ./SRC/SIFs/${RUN}.sif
done

# # After the full grid search of parameters lets make a plot showing  the convergence
# python SRC/plot_convergence.py ./Synthetic/Exp_01_elevation_dependent/hdf5
