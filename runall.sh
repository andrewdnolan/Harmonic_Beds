#!/bin/bash

NT=250                              # Number of time step
dt=2                                # size of timestep
TT=$((NT*dt))                       # total time of simulation
SIF='./SIFs/Prognostic_SpinUp.sif'  # Template SIF FILE

# Since we have multiple flow lines and still working on tweaking them
# we will save that boundary files in specific directories which describe
# the flowline and type of simulation the data is from.
DATA_FOLDER='LK_PRE_ST_full'

for OFFSET in $(seq -w 0.0 0.1 3.1);do

  # Make the offset SMB profile
  python3 ./SRC/update_SMB.py ./Data/SMB_debris.dat $OFFSET

  # Filename of offset SMB profile
  SMB="./Data/EMY_SMB_${OFFSET}_OFF.dat"

  # Model RUN identifier
  RUN="LK_PRE_${TT}a_MB_${OFFSET}_OFF"

  # Update the .SIF FILE with the model run specifc params
  sed 's#^$NT = [^ ]*#$NT = '"${NT}"'#;
       s#^$dt = [^ ]*#$dt = '"${dt}"'#;
       s#^\$RUN = [^ ]*#\$RUN = "'"${RUN}"'"#;
       s#^\$SMB_fp = [^ ]*#\$SMB_fp = "'"${SMB}"'"#;
       s#^\$OUT_FP = [^ ]*#\$OUT_FP = "'"${DATA_FOLDER}/${RUN}"'"#' "$SIF" > "./SIFs/${RUN}.sif"

  # ElmerSolver the .SIF file
  docker exec elmerenv /bin/sh -c "cd /home/glacier/shared_directory/Synthetic; ElmerSolver SIFs/${RUN}.sif" | tee ./logs/${RUN}.log

  # Remove the edited SIF to reduce clutter
  rm ./SIFs/${RUN}.sif
  # Remove the offset SMB file to save space
  rm ./Data/EMY_SMB_*_OFF.dat
done
