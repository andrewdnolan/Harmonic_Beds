Notebooks used for data analysis and visualization:

### `00.svr_regression.ipynb`
  - Fitting a support vector regression to [Young and others (2020)](https://www-cambridge-org.proxy.lib.sfu.ca/core/journals/journal-of-glaciology/article/an-imbalancing-act-the-delayed-dynamic-response-of-the-kaskawulsh-glacier-to-sustained-mass-loss/350065B3C0CD9A900DCBA7D60445D583) mass balance results.

### `01.GeometryGeneration.ipynb`
  - Reference geometry generation.
  - Correcting and smoothing the [Farinotti et al. 2019](https://www.research-collection.ethz.ch/handle/20.500.11850/315707) bed for Little Kluane.

### `02.Harmonic_Perturbations.ipynb`
  - Visualization of the harmonic perturbations.
  - Determining the most appropriate amplitude to wavelength ratio (R).

### `03.SS_postprocessing.ipynb`
  - Make volume, final free-surface, and convergence plots and spin-up animation
    for the reference geometry.
  - Aggregate the steady-state simulations for each of the harmonics. Plot S.S.
    free-surface. Also, calculate stats. about mass balance offsets for the various
    harmonics.

### `04.NS_preprocessing.ipynb`
  - Notes double checking units for sliding law in `Elmer/Ice`. Comparing slip
    coefficients in `Elmer/Ice` to Chapter 7 in Cuffey and Paterson.  

### `05.NS_postprocessing.ipynb`
  - Spectral analysis of pseudo-surge results.
  - Brinkerhoff et al. 2016 slip ratios.
  - Pseudo-surge animations.
