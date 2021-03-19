#!/usr/bin/env python3
"""
https://github.com/ICESAT-2HackWeek/intro-hdf5/blob/master/notebooks/intro-hdf5.ipynb
https://www.pythonforthelab.com/blog/how-to-use-hdf5-files-in-python/
"""
import os
import numpy as np
import xarray as xr

import argparse
from argparse import RawTextHelpFormatter


def vm(vx, vy):
    """Calculate vel. magnitude from x and y component"""
    return np.sqrt(vx**2 + vy**2)

def correct_zs_mask(H, H_min=1.0, axis=1):
    """Return mask for Valid ice thickness:
        This function will check that the ice thicknes is greater then threshold,
        and that the ice thickness is continous. In effect, this will ensure that
        not "pimples" do node downstream of the terminus with non-zero ice-thickneses
        are included.

        The return mask should be used to to mask z_s
    """
    def first_nonzero(arr, axis, invalid_val=-1):
        """https://stackoverflow.com/a/47269413/10221482"""

        mask = arr!=0
        return np.where(mask.any(axis=axis), mask.argmax(axis=axis), invalid_val)

    # Get a boolean mask of valid ice thickness, then take difference along
    # axis to check for continutiy
    cont = np.diff((H >= H_min).astype(np.int), axis=axis, append=0)

    cont[np.arange(0,H.shape[0]), first_nonzero(cont,axis)] = 0

    # Return a boolean mask
    return cont == 0

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
        type=str,
        help="filepath to directory where cleaned h5 file will be written"
    )
    parser.add_argument(
        "-Nx",
        type=int,
        help="number of gridcell"
    )
    parser.add_argument(
        "-dt",
        type=float,
        help="TimeStep size"
    )
    parser.add_argument(
        "-Beta",
        action='store_true',
        help="include slip coef? add flag if true"
    )
    return parser

def main():
    parser = getparser()
    args   = parser.parse_args()

    # Get filepath from parser
    fp     = args.fp
    Nx     = args.Nx
    dt     = args.dt

    # Get output dir from parser
    if not args.out_dir:
        # if None  then the current working directory
        out_dir = './'
    else:
        out_dir = args.out_dir


    Beta = args.Beta

    dat = np.loadtxt(fp)

    # remove directory structure is present and remove .dat file extensiosn
    # which is replaced with .h5
    out_fn = os.path.splitext(fp.split('/')[-1])[0] + '.nc'

    # Combine out_fn with the write directory
    out_fp = os.path.join(out_dir, out_fn)

    if Beta:
        # Reshape the array  to match dimensions
        dat = dat.reshape(-1,Nx,13)
    else:
        # Reshape the array  to match dimensions
        dat = dat.reshape(-1,Nx,12)
    #dat = dat.reshape(-1,Nx,11)

    # # Flip all orders to sorts ascending.
    dat = dat[:,::-1,:]

    if Beta:
        # calculate ice thickness from z_s and z_b
        H = (dat[0::2,:,7 ] - dat[0::2,:,8])
    else:
        # calculate ice thickness from z_s and z_b
        H = (dat[:,:,7 ] - dat[:,:,8])

    mask = correct_zs_mask(H, H_min=10.0, axis=1)

    print(dt)

    if Beta:
        x     = dat[0,:,4].T
        t     = dt * dat[0::2,0,0].T
        z_s   = np.where(H>=10.0, dat[0::2,:,7], dat[1::2,:,8]).T
        #z_s   = dat[0::2,:,7].T
        z_b   = dat[1::2,:,8].T
        v_s   = vm(dat[0::2,:,9], dat[0::2,:,10]).T
        v_b   = vm(dat[1::2,:,9], dat[1::2,:,10]).T
        b_dot = dat[0::2,:,11].T
        beta  = dat[1::2,:,12].T

        ds = xr.Dataset(
            {
                "z_s"  : (("x", "t"), z_s),
                "z_b"  : (("x", "t"), z_b),
                "v_s"  : (("x", "t"), v_s),
                "v_b"  : (("x", "t"), v_b),
                "b_dot": (("x", "t"), b_dot),
                "beta" : (("x", "t"), beta),
            },
            {"x":x, "t": t}
            )

    else:
        x     = dat[:,:,4].T
        t     = dt * dat[:,:,0].T
        z_s   = np.where(mask, dat[:,:,7], dat[:,:,8]).T
        z_b   = dat[:,:,8].T
        v_m   = vm(dat[:,:,9], dat[:,:,10]).T
        b_dot = dat[:,:,11].T

        ds = xr.Dataset(
            {
                "z_s"  : (("x", "t"), z_s),
                "z_b"  : (("x", "t"), z_b),
                "v_m"  : (("x", "t"), v_m),
                "b_dot": (("x", "t"), b_dot),
            },
            {"x":x, "t":t}
            )

    ds.to_netcdf(out_fp)

if __name__ == '__main__':
    main()
