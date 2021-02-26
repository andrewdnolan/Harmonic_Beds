#!/usr/bin/env python3
"""
https://github.com/ICESAT-2HackWeek/intro-hdf5/blob/master/notebooks/intro-hdf5.ipynb
https://www.pythonforthelab.com/blog/how-to-use-hdf5-files-in-python/
"""
import h5py
import numpy as np

def vm(vx, vy):
    """Calculate vel. magnitude from x and y component"""
    return np.sqrt(vx**2 + vy**2)

fp  = './Synthetic/SaveData/LK_PRE_ST_FULL/lk_pre_500a_mb_2.6_off.dat'
dat = np.loadtxt(fp)

# Reshape the array  to match dimensions
dat = dat.reshape(-1,101,11)
# Flip all oders to sorts ascending.
dat = dat[:,::-1,:]

################################################################################
# Deal with SMB data, this is not great. Need to have it written by the model
################################################################################
raw_MB = np.loadtxt('./Data/SMB_debris.dat')+ [0.0, 2.6]
coefs  = np.polyfit(raw_MB[:,0], raw_MB[:,1], 3)
b_dot  = np.polyval(coefs,dat[-1,:,4])

# calculate ice thickness from z_s and z_b
H = (dat[-1,:,7 ] - dat[-1,:,8])

with h5py.File('LK_ST_500a_mb_2.6_off.h5', 'w') as f:            # open file in write mode
    f['x'    ] = dat[-1,:,4]                                     # x-coord (0 at term)
    f['z_s'  ] = np.where(H <= 10.0, dat[-1,:,8], dat[-1,:,7 ])
    f['z_b'  ] = dat[-1,:,8 ]
    f['v_m'  ] = vm(dat[-1,:,9], dat[-1,:,10])
    f['b_dot'] = b_dot


import matplotlib.pyplot as pt

plt.plot(dat[-1,:,4]  , np.where(H <= 10.0, dat[-1,:,8], dat[-1,:,7 ]))
plt.plot(dat[-1,:,4], dat[-1,:,8 ])
plt.show()
