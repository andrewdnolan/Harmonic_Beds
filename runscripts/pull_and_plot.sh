#!/bin/bash


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# pull_and_plot.sh:
#   - pull the data from westgrid, via "rsync", to the local machine and
#     make volume and final z_s plots for each harmonic
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


H=100                                                 # Characteristic ice-thickness [ m ]
R=0.01                                                # Amplitude to Wavelength Ratio
k_max=15                                              # Maximum harmonic

RAT="perturbed_ratio-${R}"                            # directory for current value of R
OUT_FP="./plots/farinotti_corrected/dx50/${RAT}"      # where to write the figures
WESTGRID="anolan@cedar.computecanada.ca:/home/anolan" # West Grid log in

mkdir -p $OUT_FP

for k in $(seq -w 1 $((k_max+1))); do

  if [ "$k" = $((k_max+1)) ]; then
    k="01-${k_max}"
  fi

  HARM="harmonics_${k}_H_${H}"

  #-----------------------------------------------------------------------------
  # Pull the data from westgrid to the local machine
  #-----------------------------------------------------------------------------
  rsync -avP ${WESTGRID}/scratch/Harmonic_Beds/Synthetic/${RAT}/${HARM}/hdf5/*.nc \
             ./Synthetic/${RAT}/${HARM}/hdf5/

  #-----------------------------------------------------------------------------
  # Make the volume plots
  #-----------------------------------------------------------------------------
  python3 SRC/utils/plot_convergence.py \
          -fp "./Synthetic/${RAT}/${HARM}/hdf5/spinup_*.nc" \
          -mb 1.90 0.01 2.05 \
          --plot_volume      \
          --title "$ k=${k} $" \
          -out_fn "${OUT_FP}/Vol_1.9--2.5_dx_50m_k_${k}.png"

  #-----------------------------------------------------------------------------
  # Make the final z_s plot
  #-----------------------------------------------------------------------------
  python3 SRC/utils/plot_convergence.py \
          -fp "./Synthetic/${RAT}/${HARM}/hdf5/spinup_*.nc" \
          -mb 1.90 0.01 2.05 \
          --plot_Z_s         \
          --title "$ k=${k} $" \
          -out_fn "${OUT_FP}/Zs_1.9--2.5_dx_50m_k_${k}.png"

  echo
  echo "--------------------------------------------------------------------------"
  echo "% Harmonic ${k} done pulling and plotting"
  echo "--------------------------------------------------------------------------"
  echo
done
