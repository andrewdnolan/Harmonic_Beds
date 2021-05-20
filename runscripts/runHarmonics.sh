#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hystersis.sh:
#   - Numerical experiments to determine Z_s(x) sensitivity to IC with our
#     preturbed (harmonic) bed
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

R=0.01                                        # Amplitude to Wavelength Ratio
dx=100                                        # grid cell spacing [ m ] 
dt=1                                          # size of timestep  [ a ] 
NT=1001                                       # Number of time step
TT=$((NT*dt-dt))                              # total time of simulation

BED="farinotti_corrected"                     # Mesh DB for the given bed config
RAT="perturbed_ratio-${R}"                    # directory for current valye of R
EXP="exp_01_elevation_dependent"              # Experiment name
SIF="./SRC/SIFs/Hysterisis_restart.sif"       # Template SIF FILE

DOCKER=true
WESTGRID=false


# # Clean the input  file so we can create a new one with commands specifc
# if [ -f Inputs.txt ]; then
#   rm -f Inputs.txt
# fi
# # Clean the output file so we can create a new one with commands specifc
# if [ -f Outputs.txt ]; then
#   rm -f Outputs.txt
# fi

# Itterate over the harmonics
for k in $(seq -w 1 11); do

  if [ "$k" = 11 ]; then
    HARM="harmonics_01-10"
    BED_FP="./Data/Topography/pert_r_${R}_harmonics_01-10.dat"
  else
    HARM="harmonics_${k}"
    BED_FP="./Data/Topography/pert_r_${R}_harmonics_${k}.dat"
  fi

  OUT_FP="${BED}/${RAT}/${HARM}/${EXP}"

  # Make the results directory for the k-th harmonic if need be
  if [ ! -d "./Synthetic/${OUT_FP}" ];then

    mkdir -p "./Synthetic/${OUT_FP}"            # Directory for SpinUp Results
    mkdir    "./Synthetic/${OUT_FP}/SaveData"   # Elmer .dat files folders
    mkdir    "./Synthetic/${OUT_FP}/VTU"        # folder for VTU files
    mkdir    "./Synthetic/${OUT_FP}/hdf5"       # folder for .nc files

    # make the mesh for each harmonic
    if [ "$DOCKER" = true ]; then
      docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                       bash ./Mesh/makemsh.sh ./Synthetic/${OUT_FP}/mesh_dx100 100"
    elif [ "$WESTGRID" = true ]; then
      ./Mesh/makemsh.sh ./Synthetic/${OUT_FP}/mesh_dx100
    else
      echo "Either $DOCKER or $WESTGRID should be decalred as "true" "
    fi

    # Copy the .result file needed for restart into each mesh directory
    cp -v Synthetic/farinotti_smooth/exp_01_elevation_dependent/mesh_dx100/LK_PRE_3000a_dt_1_dx_100_MB_2.406_OFF.result \
          "Synthetic/${OUT_FP}/mesh_dx100"
  fi

  if [ "$k" = 11 ]; then
    # perturb the bed with the k-th harmonic of the series
    python3 ./SRC/utils/make_bed.py \
            -B Data/Topography/REF_BedTopo_2.dat \
            -O $BED_FP \
            -H 215.0   \
            -N $k      \
            -R $R      \
            --sum
  else
    # perturb the bed with the k-th harmonic of the series
    python3 ./SRC/utils/make_bed.py \
            -B Data/Topography/REF_BedTopo_2.dat \
            -O $BED_FP \
            -H 215.0   \
            -N $k      \
            -R $R
  fi

  # now run a spin up for a couple mass-balance offsets using the pertrubed bed
  for OFFSET in $(seq -w 1.90 0.01 2.00); do

    RUN="spinup_k_${k}_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"

    # Update the .SIF FILE with the model run specifc params
    sed "s#<NT>#"$NT"#g;
        s#<dt>#"$dt"#g;
        s#<RUN>#"$RUN"#g;
        s#<BED_FP>#"$BED_FP"#g;
        s#<OUT_FP>#"$OUT_FP"#g;
        s#<OFFSET>#"$OFFSET"#g" "${SIF}" > "./SRC/SIFs/${RUN}.sif"

    echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt

    echo python3 ./SRC/utils/dat2h5.py \
            "./Synthetic/${OUT_FP}/SaveData/${RUN}.dat" \
            -out_dir "./Synthetic/${OUT_FP}/hdf5"       \
            -Nx 279         \
            -dt $dt         \
            -offset $OFFSET \
            -SpinUp  >> Outputs.txt

    # # Remove the .SIF file to reduce clutter
    # rm ./SRC/SIFs/${RUN}.sif
  done
done
