#!/usr/bin/env python3

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Plotting script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import os
import sys
import glob
import argparse
import numpy as np
import xarray as xr
import pandas as pd
import scipy.linalg as LA
import matplotlib.cm as cm
import matplotlib.pyplot as plt
from matplotlib import animation, rc
import matplotlib.colors as mcolors


# Set some matplotlib parameters
plt.rcParams['text.usetex']    = False
plt.rcParams['animation.html'] = 'jshtml'


def main(argv):

    #---------------------------------------------------------------------------
    # Specify command line arguments
    #---------------------------------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("src_path", metavar="path", type=str,
                        help = "Path to .nc or .vtu files to be plotted"\
                               "enclose in quotes, accepts * as wildcard for directories or filenames")
    parser.add_argument('-T','--title', type=str,
                        help = "string for the title of the plot")
    parser.add_argument('-BP','--boundary_plot', action='store_true',
                        help = "plot surface z_s animation ")

    parser.add_argument('-Z_s','--plot_Z_s',  action='store_true',
                        help = "final z_s after mass balance grid search")
    parser.add_argument('-out_fn','--output_filename', type=str,
                        help = "full path to the output figure")

    args, _ = parser.parse_known_args(argv)

    #volume_plot = args.plot_volume
    line_plot   = args.boundary_plot

    # out_fn      = args.output_filename
    # title       = args.title
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # Load and concatenate the .nc files
    #---------------------------------------------------------------------------

    if "*" in args.src_path:
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

    out_fn = args.output_filename

    if volume_plot:
        fig = plot_volume( mf_dataset,
                           precision=len(args.mb_range[1])-2,
                           title=title)
    if z_s_plot:
        fig = plot_final_z_s( mf_dataset,
                              precision=len(args.mb_range[1])-2,
                              title=title)

    # Write the plot to a file
    fig.savefig(out_fn, dpi=400, bbox_inches='tight', facecolor='w')

    # Don't know if I actually need this
    plt.close()

if __name__ == '__main__':
    main(sys.argv[1:])
