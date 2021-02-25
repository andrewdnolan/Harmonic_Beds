#!/bin/bash

################################################################################
# This file should be within a mesh subdirecotry, within a simulation folder.
# For example:
#        Glacier_of_interest/
#       |-- Mesh/
#       |   |-- Glacier_of_interest.grd
#       |   |-- makemsh.sh                 (current file)
################################################################################


grdfile="./Mesh/Synthetic.grd"
bedfile="./Data/SMB_debris.dat"


  start=$(awk 'NR==1 {print $1}' $bedfile)
    end=$(awk 'END {print $1}'   $bedfile)


update_grd () {
  # To match scientific notation see here:
  # - https://www.uio.no/studier/emner/matnat/ifi/INF3331/h14/lectures/16sept/regex.pdf

  # https://stackoverflow.com/questions/19456518/invalid-command-code-despite-escaping-periods-using-sed
  # Replace xmin and xmax inline for the input source .grd file
  sed -i '' -e 's/^Subcell Limits 1 =.*/Subcell Limits 1 = '"${1} ${2}"'/' "${3}"

}

update_grd $start $end $grdfile

# Move the .grd file to top dir, so mesh DB is created up there
cp ${grdfile} ./

# Make the mesh with ElmerGrid. This must be executed within a Docker instance
echo "Making Elmer Compatible Grid"
echo "$ElmerGrid 1 2 ${grdfile} -autoclean"

ElmerGrid 1 2 Synthetic.grd -autoclean

# if test -f "${HOME}/shared_directory/LittleKluane/LittleKluane.grd"; then
#   rm ~/shared_directory/LittleKluane/LittleKluane.grd
# else
#   echo "Did not work. Make sure you are in top dir."
# fi
