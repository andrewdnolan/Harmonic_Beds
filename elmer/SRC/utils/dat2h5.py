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

def correct_zs_mask(H, H_min=10.0, axis=1):
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

    # Get a boolean mask of valid ice thickness (i.e. find where the H is less than 0)
    mask       = (H < H_min).astype(np.int)
    # Find the first point where __mask__ is nonzero, i.e. there is no ice thickness
    first_point = first_nonzero(mask, axis = axis)
    # Itterare over the first non-zero points. Set all downstream of it
    # to 1 (i.e. True meaning ice thickness should be 0).

    for i, point in enumerate(first_point):
        if axis == 0:
            mask[point:, i] = 1
        if axis ==1:
            mask[i, point:] = 1

    # Return a boolean mask
    return mask == 0

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
        "-SpinUp",
        action='store_true',
        help="Simulation type is a transient spin up run"
    )
    parser.add_argument(
        "-PseudoSurge",
        action='store_true',
        help="Simulation type is a transient run with increased sliding mimicing a surge"
    )
    parser.add_argument(
        "-offset",
        type=float,
        help="Mass balance offset used in the spin up to steady state"
    )
    return parser

def main():
    parser = getparser()
    args   = parser.parse_args()

    # Get filepath from parser
    fp     = args.fp
    Nx     = args.Nx
    dt     = args.dt
    SpinUp = args.SpinUp
    Pseudo = args.PseudoSurge
    offset = args.offset

    # Get output dir from parser
    if not args.out_dir:
        # if None  then the current working directory
        out_dir = './'
    else:
        out_dir = args.out_dir

    if SpinUp and Pseudo:
        raise ValueError('-SpinUp and -PseudoSurge can not both be true. Pick one or the other')
    if not SpinUp and not Pseudo:
        raise ValueError('Either -SpinUp or -PseudoSurge must be provided')

    dat = np.loadtxt(fp)

    # remove directory structure is present and remove .dat file extensiosn
    # which is replaced with .h5
    out_fn = os.path.splitext(fp.split('/')[-1])[0] + '.nc'

    # Combine out_fn with the write directory
    out_fp = os.path.join(out_dir, out_fn)

    if Pseudo:
        # Reshape the array  to match dimensions
        dat = dat.reshape(-1,Nx,15)
    if SpinUp:
        # Reshape the array  to match dimensions
        dat = dat.reshape(-1,Nx,12)
    #dat = dat.reshape(-1,Nx,11)

    if Pseudo:
        # calculate ice thickness from z_s and z_b
        H = (dat[0::2,:,7 ] - dat[0::2,:,8])
    if SpinUp:
        # calculate ice thickness from z_s and z_b
        H = (dat[:,:,7 ] - dat[:,:,8])

    mask = correct_zs_mask(H, H_min=10.0, axis=1)

    # Flip order of x-coordinate so 0 is at the start of the flowline
    dat = dat[:,::-1,:]

    if Pseudo:
        x     = dat[0,:,4].T
        t     = dt * dat[0::2,0,0].T - dt

        #z_s   = np.where(mask[:, ::-1], dat[0::2,:,7], dat[1::2,:,8]).T
        z_s   = xr.DataArray(
                data = np.where(dat[0::2,:,7] - dat[0::2,:,8] <= 10, dat[0::2,:,8], dat[0::2,:,7]).T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Elevation", units="m a.s.l.") )
        #z_b   = dat[1::2,:,8].T
        z_b   = xr.DataArray(
                data = dat[1::2,:,8].T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Bed Elevation", units="m a.s.l.") )
        #v_s   = vm(dat[0::2,:,9], dat[0::2,:,10]).T
        v_s   = xr.DataArray(
                data = vm(dat[0::2,:,9], dat[0::2,:,10]).T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Velocity (magnitude)", units="m a^{-1}") )
        #v_b   = vm(dat[1::2,:,9], dat[1::2,:,10]).T
        v_b   = xr.DataArray(
                data = vm(dat[1::2,:,9], dat[1::2,:,10]).T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Basal Velocity (magnitude)", units="m a^{-1}") )
        v_mean= xr.DataArray(
                data = vm(dat[0::2,:,13], dat[0::2,:,14]).T / 10.,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Depth Averaged Velocity (magnitude)", units="m a^{-1}") )
        #b_dot = dat[0::2,:,11].T
        b_dot = xr.DataArray(
                data = dat[0::2,:,11].T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Mass balance (Elevation dependent)", units="m a^{-1}") )
        #beta  = dat[1::2,:,12].T
        beta  = xr.DataArray(
                data = dat[1::2,:,12].T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Slip Coefficient in Elmer/Ice. Equal $\Beta^{-2}$ for Linear Wertman Sliding of form $\tau = \beta^2 u$", units="m (MPa a)^{-1}") )

        ds = xr.Dataset(
            {
                "z_s"    : z_s,
                "z_b"    : z_b,
                "v_s"    : v_s,
                "v_b"    : v_b,
                "v_mean" : v_mean,
                "b_dot"  : b_dot,
                "beta"   : beta,
            },
            {"x":x, "t": t},
            attrs=dict( description="Elmer/Ice Pseudo Surge model run")
            )

    if SpinUp:
        x     = dat[0,:,4].T
        t     = dt * dat[:,0,0].T - dt
        z_s   = xr.DataArray(
                data = np.where(dat[:,:,7] - dat[:,:,8] <= 10, dat[:,:,8], dat[:,:,7]).T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Elevation", units="m a.s.l.") )
        z_b   = xr.DataArray(
                data = dat[:,:,8].T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Bed Elevation", units="m a.s.l.") )
        v_m   = xr.DataArray(
                data = vm(dat[:,:,9], dat[:,:,10]).T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Velocity (magnitude)", units="m a^{-1}") )
        b_dot = xr.DataArray(
                data = dat[:,:,11].T,
                dims = ["x", "t"],
                coords=dict( x = x, t = t),
                attrs=dict( description="Surface Mass balance (Elevation dependent)", units="m a^{-1}") )
        ds = xr.Dataset(
            {
                "z_s"  : z_s,
                "z_b"  : z_b,
                "v_m"  : v_m,
                "b_dot": b_dot,
            },
            {"x":x, "t":t},
            attrs=dict( description="Elmer/Ice Spin Up run with a mass balance offset of {} m a^{{-1}}".format(offset))
            )

    # Write netCDF file to disk
    ds.to_netcdf(out_fp)

    print('------------------------------------------------------------------------------------------------------------')
    print('% NetCDF file written to: ')
    print('% {}'.format(out_fp))
    print('------------------------------------------------------------------------------------------------------------')

if __name__ == '__main__':
    main()
