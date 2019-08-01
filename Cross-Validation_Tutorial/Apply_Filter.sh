#!/bin/bash

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

pixelsize=$1
freq=$2
Map_mrc=$3
Mask_mrc=$4
x=$5

./programs/lowpassmap_fftw.exe << eot >> aux.log
"$Map_mrc"
"./tmp_files/temp_${x}.mrc"
$pixelsize, $freq
eot


./programs/apply_mask.exe <<eot >> aux.log
"./tmp_files/temp_${x}.mrc","$Mask_mrc"
"./tmp_files/map_${x}.txt"
$pixelsize
eot

rm ./tmp_files/temp_${x}.mrc
