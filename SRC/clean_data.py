#!/usr/bin/env python3
"""
https://github.com/ICESAT-2HackWeek/intro-hdf5/blob/master/notebooks/intro-hdf5.ipynb
https://www.pythonforthelab.com/blog/how-to-use-hdf5-files-in-python/
"""
import os
import h5py
import numpy as np
import argparse
from argparse import RawTextHelpFormatter


def vm(vx, vy):
    """Calculate vel. magnitude from x and y component"""
    return np.sqrt(vx**2 + vy**2)

def getparser():
    """ Parse input from the command line
    """
    description = "Convert .dat file to HDF5 output"

    parser = argparse.ArgumentParser(
        description=description, formatter_class=RawTextHelpFormatter
    )
    parser.add_argument(
        "fp",
        type=str,
        help="File path to output (.dat file) from SaveLine solver in Elmers"
    )
    parser.add_argument(
        "-out_dir",
        type=float,
        help="filepath to directory where cleaned h5 file will be written"
    )
    return parser

def main():
    parser = getparser()
    args   = parser.parse_args()

    # Get filepath from parser
    fp     = args.fp

    # Get output dir from parser
    if not args.out_dir:
        # if None  then the current working directory
        out_dir = './'
    else:
        out_dir = args.out_dir

    dat = np.loadtxt(fp)

    # remove directory structure is present and remove .dat file extensiosn
    # which is replaced with .h5
    out_fn = os.path.splitext(fp.split('/')[-1])[0] + '.h5'

    # Combine out_fn with the write directory
    out_fp = os.path.join(out_dir, out_fn)

    # Reshape the array  to match dimensions
    dat = dat.reshape(-1,101,12)
    #dat = dat.reshape(-1,101,11)

    # Flip all orders to sorts ascending.
    dat = dat[:,::-1,:]

    # calculate ice thickness from z_s and z_b
    H = (dat[-1,:,7 ] - dat[-1,:,8])

    #open file in write mode
    with h5py.File(out_fp, 'w') as f:
        # x-coord (0 at term)
        f['x'    ] = dat[-1,:,4]
        # Test if ice thickness greater than 10.0 (minimum ice thicknes in SIF)
        f['z_s'  ] = np.where(H <= 10.0, dat[-1,:,8], dat[-1,:,7 ])
        # Bed elevation
        f['z_b'  ] = dat[-1,:,8 ]
        # Compute velocity magnitude from x and y components
        f['v_m'  ] = vm(dat[-1,:,9], dat[-1,:,10])
        # surface mass balance
        f['b_dot'] = dat[-1,:,11]

if __name__ == '__main__':
    main()
