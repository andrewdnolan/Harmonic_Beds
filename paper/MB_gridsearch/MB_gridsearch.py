#!/usr/bin/env python

import os
import sys
import glob
import pickle
import numpy as np
import xarray as xr
import pandas as pd
import scipy.linalg as LA
import matplotlib.pyplot as plt
import scipy.interpolate as interpolate
sys.path.append('../../elmer/')
import SRC.utils.plot_spinup as plotting

# Set global matplotlib style parameters
plt.rcParams.update({'font.size': 10,
                     'text.usetex': True,
                     'figure.facecolor': 'w',
                     'savefig.bbox': 'tight'})

################################################################################
# EMY Data and SVR model loading
################################################################################
# Load the EMY data
MB  = np.load('../../elmer/Data/SMB/EMY_data/surgio_withdeb_NMB.npy') # Annual SMB
ZZ  = np.load('../../elmer/Data/SMB/EMY_data/surgio_Zs.npy')          # Elevation

# Take temporal average of mb data and convert from mwe a^{-1} to m a^{-1}
MB  = np.mean(MB,axis=0)*1000.0/910.    # Annual mean mass balance in [m a^{-1}]

# Get rid of nans and outlier
z   = ZZ[(~np.isnan(MB)) & ~(MB < -10)]
b   = MB[(~np.isnan(MB)) & ~(MB < -10)]
#return the indexes of the sorted arrays
idx = z.argsort()
#sort the arrays based on the elevation
z   = z[idx].reshape(-1,1)
b   = b[idx]


# Load the trained serialized SVR
pkl_fn = "../../elmer/Data/SMB/SVR/svr_model.pkl"
with open(pkl_fn, 'rb') as file:
    svr = pickle.load(file)

# Do prediction with the trained SVR model
b_hat = svr.predict(z)
################################################################################

################################################################################
# Reference Geometry MB gridsearch loading
################################################################################

fp      = '../../elmer/Synthetic/exp_01_elevation_dependent/hdf5/LK_*dx_50*.nc'
files   = sorted(glob.glob(fp))

xarrays = []
for file in files:
    xarrays.append(xr.open_dataset(file))

mf_dataset = xr.concat(xarrays,
                       pd.Index(data = np.linspace(1.90, 2.05, 16),
                                name = 'Delta_MB'))

mf_dataset['z_s'] = mf_dataset.z_s.where((mf_dataset.z_s - mf_dataset.z_b) != 10.,
                                          mf_dataset.z_b )
mf_dataset["H"]   = mf_dataset.z_s - mf_dataset.z_b

Vol = mf_dataset.H.integrate("x") / mf_dataset.H.isel(t=1).integrate("x")
################################################################################

################################################################################
# Figure creation
################################################################################
fig, ax = plt.subplots(1, 2, figsize=(8.5,3), constrained_layout=True)

ax[0].scatter(z, b,
           marker='o',
           s=10,
           alpha=0.5,
           facecolor="none",
           edgecolor='tab:blue',
           label='Young and others (2021)')

ax[0].plot(z,b_hat,
        color='r',
        label = 'Support Vector Regression')

ax[0].legend()
ax[0].set_ylabel('$\dot b$ (m a$^{-1}$)')
ax[0].set_xlabel('Elevation (m a.s.l.)')

# Make a colormap and all the associated var names
cmap, norm, s_map, bounds = plotting.make_colorbar(mf_dataset)

for delta_mb in Vol.Delta_MB:
    color = cmap(norm(delta_mb))
    ax[1].plot(Vol.t, Vol.sel(Delta_MB=delta_mb), color=color)

ax[1].axhline(1.0,c='k',ls=':',lw=1.0)

cbar = fig.colorbar(s_map,
                spacing='proportional',
                ticks=mf_dataset.Delta_MB,
                ax=ax[1],
                pad=0.01,
                aspect=40,
                boundaries=bounds,
                drawedges=True,
                format='%2.{}f'.format(2))
# adjust x-axis limits
ax[1].set_xlim(Vol.t.min(), Vol.t.max())
# annotate the figures axes
ax[1].set_ylabel('Relative Volume per Unit Width')
ax[1].set_xlabel('Time (a)')
# annotate the colorbar axes
cbar.set_label('$\Delta \dot b$ (m a$^{-1}$)', rotation=270, labelpad=20)
# cbar.ax.tick_params(labelsize='small')

# Major ticks every 20, minor ticks every 5
major_ticks = np.arange(0.8, 1.1, 0.05)
minor_ticks = np.arange(0.8, 1.15, 0.01)
ax[1].set_yticks(major_ticks);
ax[1].set_yticks(minor_ticks, minor=True);


ax[0].text(0.05, 0.9, 'a', transform=ax[0].transAxes,
               fontsize=12, fontweight='bold')
ax[1].text(0.05, 0.9, 'b', transform=ax[1].transAxes,
               fontsize=12, fontweight='bold')


fig.savefig('mass_balance_supp.pdf')
################################################################################
