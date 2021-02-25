#!/usr/bin/env python3
"""
https://github.com/ICESAT-2HackWeek/intro-hdf5/blob/master/notebooks/intro-hdf5.ipynb
https://www.pythonforthelab.com/blog/how-to-use-hdf5-files-in-python/
"""

import h5py
import numpy as np

def print_attrs(name, obj):
    print(name)
    for key, val in obj.attrs.items():
        print("    %s: %s" % (key, val))


with h5py.File('test_500a_mb_2.0_off.h5', 'r') as f:
    # Display datasets and their corresonding attributes
    f.visititems(print_attrs)

    H     = f['H'    ][:]  # ice thickness (m)
    x     = f['x'    ][:]  # x-coord
    v_m   = f['v_m'  ][:]  # surface velocity
    b_dot = f['b_dot'][:]  # surface mass balance
