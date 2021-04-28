#!/usr/bin/env python3

import sys
import shutil
import argparse

Lx = 1.0   # [m] length of the domain
dx = 100   # [m] gridcell spaing
Nx = Lx/dx # [ ] number of horizontal nodes

def write_grd(Lx, Nx, Ly=1, Ny=10):
    # Open the template .grd file
    template = open('Mesh/mesh_template.grd', 'r')
    # Open the new mesh to be written
    new_mesh = open('test.grd', 'w')

    # Iterate over the lines of the template file
    for line in template:

        # Set the x bounds of the mesh
        if 'Subcell Limits 1' in line:
            new_mesh.write('Subcell Limits 1 = 0 {} \n'.format(Lx))

        # Set the number of x - gridcell in
        elif 'Element Divisions 1' in line:
            new_mesh.write('Element Divisions 1 = {} \n'.format(Nx))

        # Set the number of y - gridcell in
        elif 'Element Divisions 2' in line:
            new_mesh.write('Element Divisions 2 = {} \n'.format(Ny))

        else:
            new_mesh.write(line)

    # Close the open files
    template.close()
    new_mesh.close()

def main(argv):

    # Parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-I", "--template", required = True,
                        help = "Path to template .grd file")
    parser.add_argument("-O", "--new_mesh", required = True,
                        help = "Path to write new .grd file")
    parser.add_argument("-Nx", "--Nx", required = False,
                        help = "Number of x nodes")
    parser.add_argument("-dx", "--dx", required = False,
                        help = "Gridcell spacing in x direction")
    parser.add_argument("-Lx", "--Length_x", required = False,
                        help = "Length of the domain in the x direction")

    args, _ = parser.parse_known_args(argv)

    pass

    # Check that if both Lx, Nx or dx are passed that they are comptiable
    
if __name__ == '__main__':
    main(sys.argv[1:])
