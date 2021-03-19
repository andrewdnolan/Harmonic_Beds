#!/usr/bin/env python3

import sys
import tarfile
from paraview.simple import *

fp = '/Users/andrewnolan/sfuvault/ELMERICE/Synthetic/Synthetic/Exp_01_elevation_dependent/LK_PRE_500a_MB_2.75_OFF.tar'

with tarfile.open(fp) as tar:
    for file in tar.getmembers():
        print(file.name)
