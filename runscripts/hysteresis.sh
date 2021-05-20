#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# hystersis.sh:
#   - Numerical experiments to determine Z_s(x) sensitivity to IC with our
#     preturbed (harmonic) bed
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set +x

EXP='hysteresis'                                        # Experiment (folder) name
BED='farinotti_corrected'                               # Mesh DB for the given bed config
SIF='./SRC/SIFs/Hysterisis_norestart.sif'               # Template SIF FILE
BED_FP="Data/Topography/pert_r_0.01_harmonics_01-10.dat"


NT=3001                                                 # Number of time step
dt=1                                                    # size of timestep
TT=$((NT*dt-dt))                                        # total time of simulation


DOCKER=true
WESTGRID=false

# Make top dir if it does not exist
if [ ! -d "Synthetic/${BED}/${EXP}" ]; then
  mkdir Synthetic/${BED}/${EXP}
fi
# Clean the input  file so we can create a new one with commands specifc
if [ -f Inputs.txt ]; then
  rm -f Inputs.txt
fi
# Clean the output file so we can create a new one with commands specifc
if [ -f Outputs.txt ]; then
  rm -f Outputs.txt
fi

# perturb the bed with first 10 harmonics of the series
# (i.e. evaluate the series from 1 to 10)
python3 ./SRC/utils/make_bed.py \
        -B Data/Topography/REF_BedTopo_2.dat \
        -O $BED_FP \
        -H 200.0   \
        -N 10      \
        -R 0.01    \
        --sum


for IC in "observed_IC" "smoothBed_SS_IC"; do

  # Set up neccessary directory structure and make mesh
  if [ ! -d "Synthetic/${BED}/${EXP}/${IC}" ]; then

    mkdir "Synthetic/${BED}/${EXP}/${IC}"            # Make dir for IC
    mkdir "Synthetic/${BED}/${EXP}/${IC}/SaveData"   # Elmer .dat files folders
    mkdir "Synthetic/${BED}/${EXP}/${IC}/VTU"        # folder for VTU files
    mkdir "Synthetic/${BED}/${EXP}/${IC}/hdf5"       # folder for .nc files

    if [ "$DOCKER" = true ]; then
      # Make mesh within Docker environment
      docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
                                       ./Mesh/makemsh.sh Synthetic/${BED}/${EXP}/${IC}/mesh_dx100 100"
    else
      # Make mesh driectly
      ./Mesh/makemsh.sh "Synthetic/${BED}/${EXP}/${IC}/mesh_dx100" 100
    fi

  fi

  # Get the approriate SIF template
  if [ "$IC" = "observed_IC" ]; then
    SIF="./SRC/SIFs/Hysterisis_norestart.sif"
  elif [ "$IC" = "smoothBed_SS_IC" ]; then
    SIF="./SRC/SIFs/Hysterisis_restart.sif"
  else
    echo "Invalid Initial Condition" && exit 1
  fi


  for OFFSET in $(seq -w 1.90 0.01 2.10);do
    echo
    echo "--------------------------------------------------------------------------"
    echo "% Running ${IC} with ${OFFSET} offset"
    echo "--------------------------------------------------------------------------"
    echo

    RUN="${IC}_${TT}a_dt_${dt}_dx_100_mb_${OFFSET}_off"
    OUT_FP="${BED}/${EXP}/${IC}"

    # Update the .SIF FILE with the model run specifc params
    sed "s#<NT>#"$NT"#g;
        s#<dt>#"$dt"#g;
        s#<RUN>#"$RUN"#g;
        s#<BED_FP>#"$BED_FP"#g;
        s#<OUT_FP>#"$OUT_FP"#g;
        s#<OFFSET>#"$OFFSET"#g" "${SIF}" > "./SRC/SIFs/${RUN}.sif"


    echo "./SRC/SIFs/${RUN}.sif"  >> Inputs.txt

    # # Execute the .SIF file via "ElmerSolver"
    # docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; \
    #                                 ElmerSolver ./SRC/SIFs/${RUN}.sif \
    #                                 | tee ./logs/Hystersis/Observed_IC/${RUN}.log"

    # Clean the boundary data and convert from .dat to .nc
    echo python3 ./SRC/utils/dat2h5.py \
            ./Synthetic/${OUT_FP}/SaveData/${RUN}.dat \
            -out_dir ./Synthetic/${OUT_FP}/hdf5 \
            -Nx 279 \
            -dt $dt \
            -offset $OFFSET \
            -SpinUp >> Outputs.txt

    # Remove the edited SIF to reduce clutter
    # rm ./SRC/SIFs/${RUN}.sif
  done
done
