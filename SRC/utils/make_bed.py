#!/usr/bin/env python3

"""
Following Gudmundsson, (2003) let's define our bed $z_{\rm b}$ as:
.. math::
            z_{\rm b}(x) = z_{\rm b_{\rm F}} + z_{\rm b}'

where $z_{\rm b}$ is synthetic bed profile as a function of distance along the
flowline, $z_{\rm b_{\rm F}}$ is the observed Farinotti bed (in this case smoothed),
and $z_{\rm b}'$ is our pertubation.

Pertubations take the form:
.. math::
            z_{\rm b}^{\prime} = \sum_{k=1}^{10} A_{k}
                                 \sin \left( \frac{2 \pi}{k \bar H} x \right)

where, $A_{k}$ is amplitude of the $k$-th harmonic and $\bar H$ is the mean
ice-thickness.
"""

import sys
import argparse
import numpy as np

def compute_harmonics(x, N=10, ratio=10e-3, H_bar=200.0, sum=False):
    """Compute the first N  harmonics:
        .. math::
            z_{\rm b}^{\prime} = \sum_{k=1}^{10} A_{k}
                                 \sin \left( \frac{2 \pi}{k \bar H} x \right)

        Parameters
        ----------
        x : array_like
            x-coordinate vector used to compute the harmonics       units: [m]
        N : int, optional
            Number of harmonics to compute (default=10)             units: [ ]
        ratio: float, optional
            Ratio of amplitude to wavelength (default=10e-3)        units: [m/m]
        H_bar: float, optional
            Mean ice-thickness used compute harmonics (default=200) units: [m]

        Returns
        -------
        z_prime: array_like
            Summed harmonics, representing the bed pertubation (z') units: [m]
    """

    # Compute the full series (i.e summation)
    if sum:
        M       = len(x)                   # Number of grid points
        synth   = np.zeros((M,N))          # DIM 0: x coordinate; DIM 1: k harmnoics

        # Itterate over the harmonics
        for j, k in enumerate(np.arange(1,N+1,1)):
            λ = k*H_bar                        # [m] Wavelength
            A = ratio * λ                      # [m] Amplitude of k-th harmonic

            # Compute the k-th harmonic
            synth[:,j]  = A*np.sin(((2*np.pi)/λ)*x)

        # return the summation
        return np.sum(synth, axis = 1)

    # Compute the Nth harmonic of the series
    if not sum:
        M = len(x)                         # Number of grid points
        λ = N*H_bar                        # [m] Wavelength
        A = ratio * λ                      # [m] Amplitude of k-th harmonic

        # Compute the k-th harmonic
        synth = A*np.sin(((2*np.pi)/λ)*x)

        return synth

def main(argv):

    # Parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-B", "--bed_profile", required = True,
                        help = "Path to Farinotti bed profile")
    parser.add_argument("-O", "--out_path", required = True,
                        help = "Path to write pretubed bed profile")
    parser.add_argument("-H", "--H_bar", required = True,
                        help = "Mean ice thickness (m)")
    parser.add_argument("-N", "--harmonics", required = True,
                        help = "Number of harmnoics to compute")
    parser.add_argument("-R", "--ratio", required = True,
                        help = "ratio of amplitude to wavelength (m/m)")
    parser.add_argument("-S", "--sum", action = 'store_true',
                        help = "Evaluate the series from 1 to N."\
                               "Otherwise only the Nth harmonic is computed")
    args, _ = parser.parse_known_args(argv)

    bed_fp  = args.bed_profile
    out_fp  = args.out_path
    H_bar   = float(args.H_bar)         # [m]   Mean ice-thickness
    N       = int(args.harmonics)       # [ ]   How many harmonics to computes
    ratio   = float(args.ratio)         # [m/m] ratio of amplitude to wavelength
    sum     = args.sum                  # Whether to compute the full series
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                             LOAD INPUT DATA
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    x = np.loadtxt(bed_fp)[:,0]     # x-coordinate
    z = np.loadtxt(bed_fp)[:,1]     # bed evelation (m a.s.l.)

    # Compute the bed perturbation from the sythetic waveforms
    z_prime = compute_harmonics(x, N=N, ratio=ratio, H_bar=H_bar, sum=sum)

    # Create the perturbed bed
    z_pertb = z + z_prime

    # Write the perturbed bed to a file
    np.savetxt(out_fp, np.array([x, z_pertb]).T, fmt='%.3e')

if __name__ == '__main__':
    main(sys.argv[1:])
