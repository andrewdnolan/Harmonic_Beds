#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runHarmonics_p2.sh:
#   - part-two run the pseudo suges for each spun-up harmonic
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
SIF="./SRC/SIFs/Pseudo_Surge.sif"             # Template SIF FILE

DOCKER=flase
WESTGRID=true

# Clean the input  file so we can create a new one with commands specifc
if [ -f Inputs.txt ]; then
  rm -f Inputs.txt
fi
# Clean the output file so we can create a new one with commands specifc
if [ -f Outputs.txt ]; then
  rm -f Outputs.txt
fi

# Itterate from k=0 to k_max+1 where the $k_max+1 will be the sum from 1 to k_max
for k in 00 $(seq -w 1 $((k_max+1))); do
  if [ "$k" = $((k_max+1)) ]; then
    k="01-${k_max}"
  fi

  HARM="harmonics_${k}_H_${H}"
  BED_FP="./Data/Topography/pert_r_${R}_harmonics_${k}.dat"

  # Full path should be: ${BED}/dx${dx}/${RAT}/${HARM}/${EXP} , but I get an
  # fortran error from the VtuOutputSolver.F90 file when the fp is that long
  OUT_FP="${RAT}/${HARM}" #${BED}/dx${dx} ... /${EXP}

  # Make the results directory for the k-th harmonic if need be
  if [ ! -d "./Synthetic/${OUT_FP}" ];then

    mkdir -p "./Synthetic/${OUT_FP}"            # Directory for SpinUp Results
    mkdir    "./Synthetic/${OUT_FP}/SaveData"   # Elmer .dat files folders
    mkdir    "./Synthetic/${OUT_FP}/VTU"        # folder for VTU files
    mkdir    "./Synthetic/${OUT_FP}/hdf5"       # folder for .nc files

    # make the mesh for each harmonic
    if [ "$DOCKER" = true ]; then
      docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic/elmer; \
                                       bash ./Mesh/makemsh.sh ./Synthetic/${OUT_FP}/mesh_dx${dx} ${dx}"
    elif [ "$WESTGRID" = true ]; then
      ./Mesh/makemsh.sh "./Synthetic/${OUT_FP}/mesh_dx${dx}" "${dx}"
    else
      echo "Either $DOCKER or $WESTGRID should be decalred as "true" "
    fi

  fi

  if [ "$k" = "01-${k_max}" ]; then
    # perturb the bed with the k-th harmonic of the series
    python3 ./SRC/utils/make_bed.py \
            -B Data/Topography/REF_BedTopo.dat \
            -O $BED_FP \
            -H $H      \
            -N $k_max  \
            -R $R      \
            --sum
  else
    # perturb the bed with the k-th harmonic of the series
    python3 ./SRC/utils/make_bed.py \
            -B Data/Topography/REF_BedTopo.dat \
            -O $BED_FP \
            -H $H      \
            -N $k      \
            -R $R
  fi

  #-----------------------------------------------------------------------------
  # find RESTART file and print it to a temp file
  #-----------------------------------------------------------------------------
  if [ "$k" = "00" ]; then
    OFFSET=2.01
    RUN="pseudo_k_${k}_${TT}a_dt_${dt}_dx_${dx}_mb_${OFFSET}_off"
    RESTART="LK_PRE_2000a_dt_1_dx_50_MB_2.01_OFF.result"
  else
    python3 SRC/utils/find_restart.py \
            -fp "./Synthetic/${RAT}/${HARM}/hdf5/spinup_*.nc" \
            -mb 1.90 0.01 2.05 \
            --result_filename "spinup_k_${k}_1000a_dt_1_dx_50_mb_{}_off.result" > temp

    # get value of temp file and assign to variable, delete temp file
    OFFSET=`cat temp` && rm temp
    # Define run specific variables
    RUN="pseudo_k_${k}_${TT}a_dt_${dt}_dx_${dx}_mb_${OFFSET}_off"
    RESTART="spinup_k_${k}_1000a_dt_1_dx_50_mb_${OFFSET}_off.result"
  fi


  # Update the .SIF FILE with the model run specifc params
  sed "s#<NT>#"$NT"#g;
       s#<dt>#"$dt"#g;
       s#<DX>#"$dx"#g;
       s#<RUN>#"$RUN"#g;
       s#<BED_FP>#"$BED_FP"#g;
       s#<OUT_FP>#"$OUT_FP"#g;
       s#<OFFSET>#"$OFFSET"#g;
       s#<RESTART>#"$RESTART"#g;" "${SIF}" > "./SRC/SIFs/${RUN}.sif"


  echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt

  echo python3 ./SRC/utils/dat2h5.py \
          "./Synthetic/${OUT_FP}/SaveData/${RUN}.dat" \
          -out_dir "./Synthetic/${OUT_FP}/hdf5"       \
          -Nx 555         \
          -dt $dt         \
          -offset $OFFSET \
          -PseudoSurge  >> Outputs.txt

  # # Remove the .SIF file to reduce clutter
  # rm ./SRC/SIFs/${RUN}.sif

done
