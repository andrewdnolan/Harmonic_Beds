#!/usr/bin/env python3

import os
import numpy as np
import scipy.linalg as LA
import matplotlib.pyplot as plt

# Lets use latex for plotting since it maakes figures much nicer
plt.rcParams['text.usetex'] = True

# these are parameters to be taken as input arguments, but lets hardcode them for now
fp  = '/Synthetic/SaveData/LK_PRE_ST_FULL/'  # filepath to folder with .dats
TT  = 500                                    # the simulation time

# Find the .dat files
dats = [fn for fn in os.listdir(fp) if fn.endswith('.dat') and '500' in fn and len(fn)==26]
# Sort the list of .dat files based on MB offset
dats.sort(key=lambda i: float(i.split('_')[-2]))


MB_PRE = []
for i, dat in enumerate(dats):
    dat = np.loadtxt('../Synthetic/SaveData/LK_PRE_ST_FULL/{}'.format(dat))
    dat = dat.reshape(-1,101,11)
