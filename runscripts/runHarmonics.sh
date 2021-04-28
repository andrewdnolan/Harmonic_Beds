#!/bin/bash

set +x

#-----------------------------------------------
# Part 1. Spin-ups for each Harmonic
#-----------------------------------------------

# Amplitude to Wavelength Ratio
R=0.01

# Itterate over the indivdual harmonics
for k in $(seq -w 1 10); do

  # perturb the bed with the k-th harmonic of the series
  python3 ./SRC/utils/make_bed.py \
          -B Data/Topography/REF_BedTopo.dat \
          -O Data/Topography/pert_R_${R}_harmonics_${k}.dat \
          -H 215.0 \
          -N $k \
          -R $R

  # now run a spin up for a couple mass-balance offsets
  # using the pertrubed bed
  for OFFSET in $(seq -w 2.40 0.10 2.40); do
    echo OFFSET
  done
  
  # Remove perturbed bed to reduce clutter
  rm Data/Topography/pert_R_${R}_harmonics_${k}.dat
  echo
done

# perturb the bed with first k harmonics of the series
# (i.e. evaluate the series from 1 to k)
python3 ./SRC/utils/make_bed.py \
        -B Data/Topography/REF_BedTopo.dat \
        -O Data/Topography/pert_R_${R}_harmonics_1-${k}.dat \
        -H 215.0 \
        -N $k \
        -R $R \
        --sum
