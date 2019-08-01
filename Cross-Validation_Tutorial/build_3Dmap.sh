#!/bin/bash -l

#/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#   Copyright (C) 2019 Sebastian Ortiz,  Luka Stanisic, Markus Rampp,
#    Gerhard Hummer and Pilar Cossio
#   Max Planck Institute of Biophysics, Frankfurt, Germany.
#   Max Planck Computing and Data Facility, Garching, Germany.
#
#  Released under the GNU Public License, v3.
#   See license statement for terms of distribution.
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

set -e

cd programs/

# Compile general 3D-maps programs
wget -O minimal_libraries.tar.gz https://sites.google.com/site/rubinsteingroup/compile-scripts/minimal_libraries.tar.gz
mkdir -p lib/
tar -xvzf minimal_libraries.tar.gz -C lib/
cd lib/
export PATH="$PATH:$PWD"
./rebuild_libs_gfortran

# Compile BioEM-specific programs
cd ../
gfortran lowpassmap_fftw.f90 -o lowpassmap_fftw.exe -I$FFTW_HOME/include/ ./lib/imlib2010.a ./lib/genlib.a -L$FFTW_HOME/lib -lfftw3 -lm
gfortran apply_mask_bioem.f90 -o apply_mask.exe -I$FFTW_HOME/include/ ./lib/imlib2010.a ./lib/genlib.a -L$FFTW_HOME/lib -lfftw3 -lm
cd ../

echo "Compilation done"
