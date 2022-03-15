#!/usr/bin/env python3

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Plotting script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import os
import sys
import glob
import argparse
import numpy as np
import xarray as xr
import pandas as pd
import scipy.linalg as LA
import matplotlib.cm as cm
import matplotlib.pyplot as plt
from matplotlib import animation, rc
import matplotlib.colors as mcolors


# Set some matplotlib parameters
plt.rcParams['text.usetex']    = False
plt.rcParams['animation.html'] = 'jshtml'

def make_colorbar(mf_dataset, cmap='plasma'):
    #---------------------------------------------------------------------------
    # For Seting up the colorbar:
    #    - http://csc.ucdavis.edu/~jmahoney/matplotlib-tips.html
    #---------------------------------------------------------------------------
    try:
        c_map = getattr(cm, cmap)
    except AttributeError:
        print('Invalid colormap name passed. Check matplotlib documenation')
        print('Using default: plasma')
        c_map = getattr(cm, 'plasma')

    norm = mcolors.Normalize(vmin=np.min(mf_dataset.Delta_MB),
                                  vmax=np.max(mf_dataset.Delta_MB))

    s_map = cm.ScalarMappable(norm=norm, cmap=c_map)
    s_map.set_array(mf_dataset.Delta_MB)

    # If color parameters is a linspace, we can set boundaries in this way
    halfdist = (mf_dataset.Delta_MB[1] - mf_dataset.Delta_MB[0]) / 2.0
    bounds   = np.linspace(mf_dataset.Delta_MB[0]   - halfdist,
                           mf_dataset.Delta_MB[-1]  + halfdist,
                           len(mf_dataset.Delta_MB) + 1)

    return c_map, norm, s_map, bounds

def plot_volume(mf_dataset, precision=3, title=''):

    # Make a volume xarray dataset
    Vol = mf_dataset.H.integrate("x") / mf_dataset.H.isel(t=1).integrate("x")

    # Make a colormap and all the associated var names
    cmap, norm, s_map, bounds = make_colorbar(mf_dataset)


    fig, ax = plt.subplots(figsize=(7, 5))

    for delta_mb in Vol.Delta_MB:
        color = cmap(norm(delta_mb))
        ax.plot(Vol.t[1:], Vol.sel(Delta_MB=delta_mb)[1:], color=color)

    ax.axhline(1.0,c='k',ls=':',lw=1.0)

    cbar = fig.colorbar(s_map,
                    spacing='proportional',
                    ticks=mf_dataset.Delta_MB,
                    ax=ax,
                    boundaries=bounds,
                    drawedges=True,
                    format='%2.{}f'.format(precision))

    # set the title
    ax.set_title(title)

    # adjust x-axis limits
    ax.set_xlim(Vol.t.min(), Vol.t.max())
    # annotate the figures axes
    ax.set_ylabel('Relative Volume per Unit Width')
    ax.set_xlabel('Time (a)')
    # annotate the colorbar axes
    cbar.set_label('$\Delta \dot b$ (m i.e. a$^{-1}$)', rotation=270, labelpad=20)
    cbar.ax.tick_params(labelsize='small')

    fig.tight_layout()

    return fig, ax, cbar

def plot_final_z_s(mf_dataset, precision=3, title=''):
    # Make a colormap and all the associated var names
    cmap, norm, s_map, bounds = make_colorbar(mf_dataset)

    fig, ax = plt.subplots(figsize=(9, 5))

    for delta_mb in mf_dataset.Delta_MB:
        color = cmap(norm(delta_mb))
        ax.plot(mf_dataset.x/1000., mf_dataset.isel(t=-1).z_s.sel(Delta_MB=delta_mb), color=color)

    ax.plot(mf_dataset.x/1000., mf_dataset.isel(t=0,Delta_MB=0).z_b, color='k', label=r'$z_{\rm b}$')
    ax.plot(mf_dataset.x/1000., mf_dataset.isel(t=1,Delta_MB=0).z_s,
            color='k', ls=':', lw=1.0, label=r'$z_{\rm s}(t=0)$')

    ax.fill_between(mf_dataset.x/1000., mf_dataset.isel(t=0,Delta_MB=0).z_b, color='gray', alpha=0.5)

    cbar = fig.colorbar(s_map,
                        spacing='proportional',
                        ticks=mf_dataset.Delta_MB,
                        ax=ax,
                        boundaries=bounds,
                        drawedges=True,
                        format='%2.2f')

    ax.legend()

    # set the title
    ax.set_title(title)

    ax.set_xlabel('Length (km)')
    ax.set_ylabel('Elevation (m a.s.l.)')
    ax.set_xlim(0,np.max(mf_dataset.x)/1000.)
    ax.set_ylim(1200, None)

    # annotate the colorbar axes
    cbar.set_label('$\Delta \dot b$ (m i.e. a$^{-1}$)', rotation=270, labelpad=20)
    cbar.ax.tick_params(labelsize='small')

    fig.tight_layout()

    return fig, ax, cbar

def plot_convergence(mf_dataset, precision=3, title=''):
    # Make a colormap and all the associated var names
    cmap, norm, s_map, bounds = make_colorbar(mf_dataset)

    fig, ax = plt.subplots(1,1)

    # Make a volume xarray dataset
    Vol = mf_dataset.H.integrate("x") / mf_dataset.H.isel(t=1).integrate("x")

    # Loop over mass balance offsets
    for delta_mb in Vol.Delta_MB:
        color = cmap(norm(delta_mb))
        ax.plot(Vol.t[1:],
                # derivative of realtive volume w.r.t.
                np.abs(Vol.sel(Delta_MB=delta_mb)[1:].differentiate('t')),
                color=color)

    cbar = fig.colorbar(s_map,
                    spacing='proportional',
                    ticks=mf_dataset.Delta_MB,
                    ax=ax,
                    boundaries=bounds,
                    drawedges=True,
                    format='%2.{}f'.format(precision))

    # set the title
    ax.set_title(title)

    # adjust x-axis limits
    ax.set_xlim(Vol.t.min(), Vol.t.max())

    # annotate the colorbar axes
    cbar.set_label('$\Delta \dot b$ (m i.e. a$^{-1}$)', rotation=270, labelpad=20)
    cbar.ax.tick_params(labelsize='small')

    # Set axis labels
    ax.set_ylabel(r"$\left| \frac{\partial V'}{\partial t} \right|$", fontsize='xx-large')
    ax.set_xlabel('Time (a)')

    # Show convergence threshold
    ax.axhline(1e-6, ls=':', c='k', lw=1.0)
    ax.set_yscale('log')

    return fig, ax, cbar

def animate_z_s(mf_dataset, stride=10, figsize=(9,3), title=''):

    fig, ax = plt.subplots(figsize=figsize, constrained_layout=True)

    # Set the x and y limits, which do not change throughout animation
    ax.set_xlim(0,np.max(mf_dataset.x)/1000.)
    ax.set_ylim(mf_dataset.z_s.min(),
                mf_dataset.z_s.isel(t=0).max() + \
                (mf_dataset.z_s.isel(t=0).max() - mf_dataset.z_s.isel(t=0).min())/ 10 )

    # Set axes labels, which do not change throughout animation
    ax.set_ylabel('Elevation (m a.s.l.)')
    ax.set_xlabel('Distance along flowline (km)')

    # Plot the bed which is constant throughout animation
    ax.plot(mf_dataset.x/1000.,
            mf_dataset.isel(t=0).z_b,
            color='k', label=r'$z_{\rm b}$')

    # Plot the initial condition
    ax.plot(mf_dataset.x/1000.,
            mf_dataset.isel(t=0).z_s,
            ls = ':', lw = 1.0,
            color='k', label=r'$z_{\rm s}(t=0)$')

    # Fill between bed and bottom of plot
    ax.fill_between(mf_dataset.x/1000.,
                    mf_dataset.isel(t=0).z_b,
                    y2=np.minimum(mf_dataset.isel(t=0).z_b.min(), 0.0),
                    color='gray', alpha=0.5)

    ax.legend()
    ax.set_title(title)

    line1, = ax.plot([], [], lw=2, color='tab:blue', label='$z_s(t=0.0)$',)
    line   = [line1]

    # Function to be animated
    def animate(i):
        # plot the free surface
        line[0].set_data(mf_dataset.x/1000.,
                         mf_dataset.isel(t=i).z_s)
        line[0].set_label('$z_s(t={{{:.1f}}})$'.format(mf_dataset.t.isel(t=i).values))

        ax.fill_between(mf_dataset.x/1000.,
                        mf_dataset.isel(t=0).z_b,
                        y2=np.minimum(mf_dataset.isel(t=0).z_b.min(), 0.0),
                        color='gray', alpha=0.5)
        ax.legend()

        return line

    NT = mf_dataset.t.size
    anim = animation.FuncAnimation(fig, animate,
                                   frames=np.arange(0, NT, stride),
                                   interval=50,
                                   blit=True)
    plt.close()
    return anim


def main(argv):

    #---------------------------------------------------------------------------
    # Specify command line arguments
    #---------------------------------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("src_path", metavar="path", type=str,
                        help = "Path to .nc files to be plotted"\
                               "enclose in quotes, accepts * as wildcard for directories or filenames")
    parser.add_argument('-mb','--mb_range', nargs='+',
                        help = "mimics 'seq' unix commands where:"\
                               " first value is start"\
                               " middle values is stride"\
                               " last value is stop")
    parser.add_argument('-T','--title', type=str,
                        help = "string for the title of the plot")
    parser.add_argument('-V','--plot_volume', action='store_true',
                        help = "volume convergence plots after mass balance grid search")
    parser.add_argument('-Z_s','--plot_Z_s',  action='store_true',
                        help = "final z_s after mass balance grid search")
    parser.add_argument('-out_fn','--output_filename', type=str,
                        help = "full path to the output figure")

    args, _ = parser.parse_known_args(argv)

    volume_plot = args.plot_volume
    z_s_plot    = args.plot_Z_s
    out_fn      = args.output_filename
    title       = args.title
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # Load and concatenate the .nc files
    #---------------------------------------------------------------------------

    # Glob the file paths and return list of files
    files = sorted(glob.glob(args.src_path))

    # Raise error if glob didn't work
    if not files:
        raise OSError('value passed for "src_path" is invalid')

    # Create array of mass balance values used in spin-up
    MB, dx = np.linspace(float(args.mb_range[0]),
                         float(args.mb_range[2]),
                         len(files),
                         retstep=True)

    # Check the the MB stride is the same as the stride that was specified
    if not np.isclose(dx, float(args.mb_range[1])):
        raise OSError('MB stride passed does not match that of files found')

    # Make an empty list to store the read in .nc files
    xarrays = []

    # Iterate over each .nc file and read in with xarray
    for file in files:
        xarrays.append(xr.open_dataset(file))

    # Concatenate the .nc files via their mass balance offset
    mf_dataset = xr.concat(xarrays,
                           pd.Index(data = MB, name='Delta_MB'))
    # Correct for mimimum thickness
    # NOTE:: This shoud have been done in the dat2h5.py file but it's not working
    mf_dataset['z_s'] = mf_dataset.z_s.where((mf_dataset.z_s - mf_dataset.z_b) != 10., mf_dataset.z_b)
    mf_dataset["H"]   = mf_dataset.z_s - mf_dataset.z_b
    # Flip the x-coordinate to more accurately match the map view representation of LK
    mf_dataset['x'] = mf_dataset['x'][::-1]
    #---------------------------------------------------------------------------

    out_fn = args.output_filename

    if volume_plot:
        fig, _, _  = plot_volume( mf_dataset,
                           precision=len(args.mb_range[1])-2,
                           title=title)
    if z_s_plot:
        fig, _, _  = plot_final_z_s( mf_dataset,
                              precision=len(args.mb_range[1])-2,
                              title=title)

    # Write the plot to a file
    fig.savefig(out_fn, dpi=400, bbox_inches='tight', facecolor='w')

    # Don't know if I actually need this
    plt.close()

if __name__ == '__main__':
    main(sys.argv[1:])
