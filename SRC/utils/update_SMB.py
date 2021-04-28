#!/usr/bin/env python3

import argparse
import numpy as np
from argparse import RawTextHelpFormatter

"""
This utility is archived since this is dependent upon a position based mass
balance forcing. We have oppted for the more complex forcing using an elevation
dependent SV regression of EMY's SMB model data. 
"""
fp     = '../Data/SMB_debris.dat'
offset = 1.5

def offset_dat(fp, offset):
    """ Method of actually offset the data
    """
    # Read the src .dat file
    EMY_SMB      = np.loadtxt(fp)

    # Add offset to the second (SMB in m/yr) column
    EMY_SMB[:,1] = EMY_SMB[:,1]+offset

    # Write the new offseted data with a descriptive file name
    np.savetxt('./Data/EMY_SMB_{}_OFF.dat'.format(offset), EMY_SMB, fmt='%.3e')

def getparser():
    description = "Offset the SMB .dat file used for SS simulation "

    parser = argparse.ArgumentParser(
        description=description, formatter_class=RawTextHelpFormatter
    )
    parser.add_argument(
        "fp",
        type=str,
        help="File path to the input SMB (m/yr) .dat file"
    )
    parser.add_argument(
        "offset",
        type=float,
        help="scalar value (float) to offset the SMB data"
    )
    return parser

def main():
    parser = getparser()
    args   = parser.parse_args()

    fp     = args.fp
    offset = float(args.offset)

    offset_dat(fp, offset)
if __name__ == '__main__':
    main()
