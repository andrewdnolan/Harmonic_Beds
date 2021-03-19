#!/usr/bin/env python3


import os
import sys
import numpy as np
import xarray as xr
import scipy.linalg as LA

import matplotlib.cm as cm
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
plt.rcParams['text.usetex'] = True

data_folder = str(sys.argv[1])

if not os.path.exists(data_folder):
    raise FileNotFoundError('Can\'t find specified folder')

# intialize empty list
hdf5s = []
for fn in os.listdir(data_folder):
    if fn.endswith('.h5'):
        hdf5s.append(os.path.join(data_folder, fn) )

# Sort them based off the offset
hdf5s.sort(key=lambda i: float('.'.join(i.split('_')[-2].split('.'))))


xarrays = []
for hdf5 in hdf5s:
    xarrays.append(xr.open_dataset(hdf5))

surface_values = xr.concat(xarrays, dim='offset')


############################################################
# For Seting up the colorbar:
#    - http://csc.ucdavis.edu/~jmahoney/matplotlib-tips.html
############################################################
del_bd = np.linspace(0.00,2.50,len(xarrays))

colormap = cm.plasma
normalize = mcolors.Normalize(vmin=del_bd.min(),
                              vmax=del_bd.max())

# Colorbar setup
s_map = cm.ScalarMappable(norm=normalize, cmap=colormap)
s_map.set_array(surface_values.offset.values)

# If color parameters is a linspace, we can set boundaries in this way
halfdist   = (del_bd[1] - del_bd[0])/2.0
boundaries = np.linspace(del_bd[0] - halfdist, del_bd[-1] + halfdist, len(del_bd) + 1)
plasma     = plt.cm.plasma(np.linspace(0,1,len(del_bd)))

fig, ax = plt.subplots(2,1, sharex=True, constrained_layout=True, figsize=(7.0,6.0))

ax[0].axhline(1.0,c='k',ls=':',lw=1, alpha=0.5)
ax[1].axhline(1.0,c='k',ls=':',lw=1, alpha=0.5)

T_vec = (surface_values.phony_dim_0.values + 1) * 2.
for offset in surface_values.offset.values:
    dat = surface_values.sel(offset=offset)
    H   = dat.z_s - dat.z_b

    L    = np.count_nonzero(H[:,:] > 10., axis=1)/np.count_nonzero(H[0,:] > 10.)
    Vol  = np.trapz(H[:,:] / np.trapz(H[0,:]), axis=1)

    color = colormap(normalize(del_bd[offset]))

    ax[0].plot(T_vec, L  , color=color)
    ax[1].plot(T_vec, Vol, color=color)

ax[0].set_title( 'Test Glacier $\Delta \dot b$ Experiment')
ax[0].set_ylabel('Relative Length') #km
ax[1].set_ylabel('Relative Volume per Unit Width') #(km$^2$)
ax[1].set_xlabel('Time (y)')

cbar = fig.colorbar(s_map, spacing='proportional', ticks=del_bd, ax=ax, boundaries=boundaries, drawedges=True, format='%2.2f')
cbar.set_label('$\Delta \dot b$ (m a$^{-1}$)', rotation=270, labelpad=20)

#plt.show()
fig.savefig('./plots/TG_exp1_Vol_n_L.png',dpi=600,bbox_inches='tight',facecolor="w")
