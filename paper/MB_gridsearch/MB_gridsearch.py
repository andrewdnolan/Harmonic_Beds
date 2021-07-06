#!/usr/bin/env python

import os
import sys
import glob
import numpy as np
import xarray as xr
import pandas as pd
import scipy.linalg as LA
import matplotlib.pyplot as plt
import scipy.interpolate as interpolate

sys.path.append('../../elmer/')
import SRC.utils.plot_spinup as plotting

plt.rcParams['text.usetex'] = True

fp      = '../../elmer/Synthetic/exp_01_elevation_dependent/hdf5/LK_*dx_50*.nc'
files   = sorted(glob.glob(fp))

xarrays = []
for file in files:
    xarrays.append(xr.open_dataset(file))

mf_dataset = xr.concat(xarrays,
                       pd.Index(data = np.linspace(1.90, 2.05, 16), name='Delta_MB'))

mf_dataset['z_s'] = mf_dataset.z_s.where((mf_dataset.z_s - mf_dataset.z_b) != 10., mf_dataset.z_b)
mf_dataset["H"]   = mf_dataset.z_s - mf_dataset.z_b

Vol = mf_dataset.H.integrate("x") / mf_dataset.H.isel(t=1).integrate("x")


# Major ticks every 20, minor ticks every 5
major_ticks = np.arange(0.8, 1.1, 0.05)
minor_ticks = np.arange(0.8, 1.15, 0.01)

title = r'\begin{center}'  + \
        r'$2000 \; \rm{a}$ spin-up of Synthetic Glacier (Surging Tributary) \\'  + \
        r'using a support vector regression of EMY $\dot b$ data (elevation dependent)'  + \
        r' \end{center}'

fig, ax = plotting.plot_volume(mf_dataset, precision=2) #, title=title

ax.set_yticks(major_ticks);
ax.set_yticks(minor_ticks, minor=True);

fig.savefig('./mb_gridsearch_Vol.eps', facecolor='w', bbox_inches = 'tight', edgecolor='k')
