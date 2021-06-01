# Harmonic Beds for Bayes Inversion


__To Do__:

  - [ ] Some convergence study of the iterative solver and the best preconditioners
        would be really helpful in speeding up the runs (maybe...)

  - [ ] Can you avoid the reverse bed-slope at headwall node by tweaking the
        surface and bed profiles ever so slightly?
        - Making the bed slope steeper at the top node might help prevent the
          reverse surface slope.

  - [ ] For some reason the spin-up runs no longer write the initial condition
        for t=0. Why is this? I know they were before, I don't think anythings
        changed which would have affected this??   
    - I think for some reason on this has to do with specifying the bed file
      as an init instead of JUST in the BC section. Compare to the Pseudo surge .SIF
      for a point a comparison where writing the IC works.

  - [ ] Set Scripts up to take command line flag, whether running in docker or
        westgrid so don't need to comment things in/out when you want to swtich
        where you are runnning.
        2686024
