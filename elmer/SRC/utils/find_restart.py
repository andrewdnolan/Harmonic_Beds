#!/usr/bin/env python3


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Find restart file
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import os
import sys
import glob
import argparse
import numpy as np
import xarray as xr
import pandas as pd

def find_Delta_V_eq_0(mf_dataset):

    # Make a volume xarray
    Vol = mf_dataset.H.integrate("x") / mf_dataset.H.isel(t=1).integrate("x")
    # Find the index of the value closest to relative volume of 1
    idx = np.abs(Vol.isel(t=-1).values - 1.0).argmin()

    return idx

def main(argv):
    #---------------------------------------------------------------------------
    # Specify command line arguments
    #---------------------------------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("src_path", metavar="path", type=str,
                        help = "Path to .nc files to be plotted"\
                               "enclose in quotes, accepts * as wildcard for directories or filenames")
    parser.add_argument('-mb','--mb_range', nargs='+',
                        help = "mimics 'seq' unix commands where:"\
                               " first value is start"\
                               " middle values is stride"\
                               " last value is stop")
    parser.add_argument("-r_fn", '--result_filename', type=str,
                        help = "results file missing the mass balance offset"\
                               "to be found and filled in")
    args, _ = parser.parse_known_args(argv)

    result_filename = args.result_filename
    #---------------------------------------------------------------------------
    # Load and concatenate the .nc files
    #---------------------------------------------------------------------------

    # Glob the file paths and return list of files
    files = sorted(glob.glob(args.src_path))

    # Raise error if glob didn't work
    if not files:
        raise OSError('value passed for "src_path" is invalid')

    # Create array of mass balance values used in spin-up
    MB, dx = np.linspace(float(args.mb_range[0]),
                         float(args.mb_range[2]),
                         len(files),
                         retstep=True)

    # Check the the MB stride is the same as the stride that was specified
    if not np.isclose(dx, float(args.mb_range[1])):
        raise OSError('MB stride passed does not match that of files found')

    # Make an empty list to store the read in .nc files
    xarrays = []

    # Iterate over each .nc file and read in with xarray
    for file in files:
        xarrays.append(xr.open_dataset(file))

    # Concatenate the .nc files via their mass balance offset
    mf_dataset = xr.concat(xarrays,
                           pd.Index(data = MB, name='Delta_MB'))
    # Correct for mimimum thickness
    # NOTE:: This shoud have been done in the dat2h5.py file but it's not working
    mf_dataset['z_s'] = mf_dataset.z_s.where((mf_dataset.z_s - mf_dataset.z_b) != 10., mf_dataset.z_b)
    mf_dataset["H"]   = mf_dataset.z_s - mf_dataset.z_b
    #---------------------------------------------------------------------------

    idx     = find_Delta_V_eq_0(mf_dataset)
    #restart = result_filename.format(MB[idx])

    print("{:.2f}".format(MB[idx]), file=sys.stdout)
    #os.environ['RESTART'] = str(restart)


if __name__ == '__main__':
    main(sys.argv[1:])
