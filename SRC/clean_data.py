# #!/usr/bin/env python3
#
# import argparse
# import numpy as np
# from argparse import RawTextHelpFormatter
#
# fp     = '../Data/SMB_debris.dat'
# offset = 1.5
#
# def offset_dat(fp, offset):
#     """ Method of actually offset the data
#     """
#     # Read the src .dat file
#     EMY_SMB      = np.loadtxt(fp)
#
#     # Add offset to the second (SMB in m/yr) column
#     EMY_SMB[:,1] = EMY_SMB[:,1]+offset
#
#     # Write the new offseted data with a descriptive file name
#     np.savetxt('./Data/EMY_SMB_{:1.2f}_OFF.dat'.format(offset), EMY_SMB, fmt='%.3e')
#
# def getparser():
#     description = "Offset the SMB .dat file used for SS simulation "
#
#     parser = argparse.ArgumentParser(
#         description=description, formatter_class=RawTextHelpFormatter
#     )
#     parser.add_argument(
#         "fp",
#         type=str,
#         help="File path to the input SMB (m/yr) .dat file"
#     )
#     parser.add_argument(
#         "offset",
#         type=float,
#         help="scalar value (float) to offset the SMB data"
#     )
#     return parser
#
# def main():
#     parser = getparser()
#     args   = parser.parse_args()
#
#     fp     = args.fp
#     offset = float(args.offset)
#
#     offset_dat(fp, offset)
# if __name__ == '__main__':
#     main()

"""
https://github.com/ICESAT-2HackWeek/intro-hdf5/blob/master/notebooks/intro-hdf5.ipynb
https://www.pythonforthelab.com/blog/how-to-use-hdf5-files-in-python/
"""
import h5py
import numpy as np

fp  = 'lk_pre_500a_mb_2.0_off.dat'
dat = np.loadtxt(fp)
dat = dat.reshape(-1,101,11)
dat = dat[:,::-1,:]

# Mask the surface elevation to bed elevation for anything less than bed elevation + 10.0
dat[:,:,7][dat[:,:,7] < dat[:,:,8]+10] = dat[:,:,8][dat[:,:,7] < dat[:,:,8]+10]

with h5py.File('test_500a_mb_2.0_off.h5', 'w') as f:                           # open file in write mode
    f['x'    ] = dat[-1,:,4]                                     # x-coord (0 at term)
    f['v_m'  ] = np.sqrt(dat[-1,:,9]**2 + dat[-1,:,10]**2)
    f['b_dot'] = 0.004330612803970763*dat[-1,:,5]-10.6039+1.50
    H          = dat[-1,:,7] - dat[-1,:,8]
    f['H'    ] = np.where(H < 10.5, 0, H)

    f['x'    ].attrs['units'] = 'idx'
    f['v_m'  ].attrs['units'] = 'm a^{-1}'
    f['b_dot'].attrs['units'] = 'm w.e. a^{-1}'
    f['H'    ].attrs['units'] = 'm'
