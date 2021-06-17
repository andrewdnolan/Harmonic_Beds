#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

H=100                                         # Characteristic ice-thickness [ m ]
R=0.01                                        # Amplitude to Wavelength Ratio
k_max=15                                      # Maximum harmonic

dx=50                                         # grid cell spacing [ m ]
dt=0.1                                        # size of timestep  [ a ]
NT=101                                        # Number of time step
TT=$(awk -v NT=$NT -v dt=$dt "BEGIN { print NT*dt - dt }" )

BED="farinotti_corrected"                     # Mesh DB for the given bed config
RAT="perturbed_ratio-${R}"                    # directory for current value of R
EXP="exp_02_sliding"                          # Experiment name
SIF="./SRC/SIFs/Pseudo_Surge_NonLinWeertman.sif" # Template SIF FILE

DOCKER=true
WESTGRID=false

k="01-${k_max}"

HARM="harmonics_${k}_H_${H}"
BED_FP="./Data/Topography/pert_r_${R}_harmonics_${k}.dat"

# Full path should be: ${BED}/dx${dx}/${RAT}/${HARM}/${EXP} , but I get an
# fortran error from the VtuOutputSolver.F90 file when the fp is that long
OUT_FP="${RAT}/${HARM}" #${BED}/dx${dx} ... /${EXP}

#-----------------------------------------------------------------------------
# find RESTART file and print it to a temp file
#-----------------------------------------------------------------------------
python3 SRC/utils/find_restart.py \
        -fp "./Synthetic/${RAT}/${HARM}/hdf5/spinup_*.nc" \
        -mb 1.90 0.01 2.05 \
        --result_filename "spinup_k_${k}_1000a_dt_1_dx_50_mb_{}_off.result" > temp

# get value of temp file and assign to variable, delete temp file
OFFSET=`cat temp` && rm temp

# Define run specific variables
RUN="pseudo_k_${k}_${TT}a_dt_${dt}_dx_${dx}_mb_${OFFSET}_off"
RESTART="spinup_k_${k}_1000a_dt_1_dx_50_mb_${OFFSET}_off_nonlin.result"
echo
echo "RUN:     ${RUN}"
echo "RESTART: ${RESTART}"

# # Update the .SIF FILE with the model run specifc params
# sed "s#<NT>#"$NT"#g;
#      s#<dt>#"$dt"#g;
#      s#<DX>#"$dx"#g;
#      s#<RUN>#"$RUN"#g;
#      s#<BED_FP>#"$BED_FP"#g;
#      s#<OUT_FP>#"$OUT_FP"#g;
#      s#<OFFSET>#"$OFFSET"#g;
#      s#<RESTART>#"$RESTART"#g;" "${SIF}" > "./SRC/SIFs/${RUN}.sif"



# echo python3 ./SRC/utils/dat2h5.py \
#         "./Synthetic/${OUT_FP}/SaveData/${RUN}.dat" \
#         -out_dir "./Synthetic/${OUT_FP}/hdf5"       \
#         -Nx 555         \
#         -dt $dt         \
#         -offset $OFFSET \
#         -PseudoSurge  >> Outputs.txt
