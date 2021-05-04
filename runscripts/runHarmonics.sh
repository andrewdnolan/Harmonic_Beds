#!/bin/bash

set +x

#-------------------------------------------------------------------------------
# Part 1. Spin-ups for each Harmonic
#-------------------------------------------------------------------------------

# Amplitude to Wavelength Ratio
R=0.01

# Elmer Run parameters
NT=3001                                              # Number of time step
dt=1                                                 # size of timestep
SIF='./SRC/SIFs/Hysterisis_restart.sif'              # Template SIF FILE
EXP="Exp_01_elevation_dependent"
RAT="perturbed_ratio-0.01"

DOCKER=true
WESTGRID=false


# Clean the input  file so we can create a new one with commands specifc
if [ -f Inputs.txt ]; then
  rm -f Inputs.txt
fi
# Clean the output file so we can create a new one with commands specifc
if [ -f Outputs.txt ]; then
  rm -f Outputs.txt
fi

# Itterate over the indivdual harmonics
for k in $(seq -w 1 10); do

  BED="harmonics_${k}"
  BED_FP="./Data/Topography/pert_r_${R}_harmonics_${k}.dat"

  # Make the results directory for the k-th harmonic if need be
  if [ ! -d "./Synthetic/${RAT}/${BED}" ];then
    # Top Results Directory
    mkdir "./Synthetic/${RAT}/${BED}"
    # Directory for SpinUp Results
    mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent"
    # Elmer .dat files folders
    mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/SaveData"
    # folder for VTU files
    mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/VTU"
    # folder for .nc files
    mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/hdf5"

    # make the mesh for each harmonic
    if [ "$DOCKER" = true ]; then
      docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                          bash ./Mesh/makemsh.sh ./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/mesh_dx100"
    elif [ "$WESTGRID" = true ]; then
      bash ./Mesh/makemsh.sh ./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/mesh_dx100
    else
      echo "Either $DOCKER or $WESTGRID should be decalred as "true" "
    fi

    # Copy the .result file needed for restart into each mesh directory
    cp -v Synthetic/farinotti_smooth/exp_01_elevation_dependent/mesh_dx100/LK_PRE_3000a_dt_1_dx_100_MB_2.406_OFF.result \
          Synthetic/${RAT}/${BED}/${EXP}/mesh_dx100
  fi

  # perturb the bed with the k-th harmonic of the series
  python3 ./SRC/utils/make_bed.py \
          -B Data/Topography/REF_BedTopo.dat \
          -O $BED_FP \
          -H 215.0   \
          -N $k      \
          -R $R


  # now run a spin up for a couple mass-balance offsets using the pertrubed bed
  for OFFSET in $(seq -w 2.35 0.01 2.45); do

    RUN="spinup_k_${k}_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"

    # Update the .SIF FILE with the model run specifc params
    sed "s#<NT>#"$NT"#g;
         s#<dt>#"$dt"#g;
         s#<EXP>#"$EXP"#g;
         s#<BED>#"$BED"#g;
         s#<RAT>#"$RAT"#g;
         s#<RUN>#"$RUN"#g;
         s#<BED_FP>#"$BED_FP"#g;
         s#<OFFSET>#"$OFFSET"#g" "$SIF" > "./SRC/SIFs/${RUN}.sif"

    echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt

    echo python3 ./SRC/utils/dat2h5.py \
            ./Synthetic/${RAT}/${BED}/${EXP}/SaveData/${RUN}.dat \
            -out_dir ./Synthetic/${RAT}/${BED}/${EXP}/hdf5 \
            -Nx 284 \
            -dt $dt \
            -offset $OFFSET \
            -SpinUp  >> Outputs.txt
    # Remove the .SIF file to reduce clutter
    rm ./SRC/SIFs/${RUN}.sif
  done

  # Remove perturbed bed to reduce clutter
  rm Data/Topography/pert_r_${R}_harmonics_${k}.dat
  echo

done

#-------------------------------------------------------------------------------
# Part 2. Spin-up for each all harmonics summed
#-------------------------------------------------------------------------------

BED="harmonics_01-10"
BED_FP="./Data/Topography/pert_r_${R}_harmonics_${k}.dat"


# perturb the bed with first k harmonics of the series
# (i.e. evaluate the series from 1 to k)
# perturb the bed with the k-th harmonic of the series
python3 ./SRC/utils/make_bed.py \
        -B Data/Topography/REF_BedTopo.dat \
        -O $BED_FP \
        -H 215.0   \
        -N $k      \
        -R $R      \
        --sum

# Make the results directory for the k-th harmonic if need be
if [ ! -d "./Synthetic/${RAT}/${BED}" ];then
  # Top Results Directory
  mkdir "./Synthetic/${RAT}/${BED}"
  # Directory for SpinUp Results
  mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent"
  # Elmer .dat files folders
  mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/SaveData"
  # folder for VTU files
  mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/VTU"
  # folder for .nc files
  mkdir "./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/hdf5"

  # make the mesh for each harmonic
  if [ "$DOCKER" = true ]; then
    docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                        bash ./Mesh/makemsh.sh ./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/mesh_dx100"
  elif [ "$WESTGRID" = true ]; then
    bash ./Mesh/makemsh.sh ./Synthetic/${RAT}/${BED}/Exp_01_elevation_dependent/mesh_dx100
  else
    echo "Either $DOCKER or $WESTGRID should be decalred as "true" "
  fi

  # Copy the .result file needed for restart into each mesh directory
  cp -v Synthetic/farinotti_smooth/exp_01_elevation_dependent/mesh_dx100/LK_PRE_3000a_dt_1_dx_100_MB_2.406_OFF.result \
        Synthetic/${RAT}/${BED}/${EXP}/mesh_dx100
fi

# now run a spin up for a couple mass-balance offsets using the pertrubed bed
for OFFSET in $(seq -w 2.35 0.01 2.45); do

  RUN="spinup_k_01-10_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"

  # Update the .SIF FILE with the model run specifc params
  sed "s#<NT>#"$NT"#g;
       s#<dt>#"$dt"#g;
       s#<EXP>#"$EXP"#g;
       s#<BED>#"$BED"#g;
       s#<RAT>#"$RAT"#g;
       s#<RUN>#"$RUN"#g;
       s#<BED_FP>#"$BED_FP"#g;
       s#<OFFSET>#"$OFFSET"#g" "$SIF" > "./SRC/SIFs/${RUN}.sif"

  echo "./SRC/SIFs/${RUN}.sif" >> Inputs.txt

  echo python3 ./SRC/utils/dat2h5.py \
          ./Synthetic/${RAT}/${BED}/${EXP}/SaveData/${RUN}.dat \
          -out_dir ./Synthetic/${RAT}/${BED}/${EXP}/hdf5 \
          -Nx 284 \
          -dt $dt \
          -offset $OFFSET \
          -SpinUp  >> Outputs.txt
  # Remove the .SIF file to reduce clutter
  rm ./SRC/SIFs/${RUN}.sif
done
# Remove perturbed bed to reduce clutter
rm Data/Topography/pert_r_${R}_harmonics_${k}.dat

echo
