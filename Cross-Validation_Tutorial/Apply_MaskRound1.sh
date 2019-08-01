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

########## Script for masking the map and converting it into bioEM #######

param=$1
input=$2

Map_mrc=`grep -w "MAP_ROUND1" $input|awk '{print $2}'`
Mask_mrc=`grep -w "MASK" $input|awk '{print $2}'`
pixelsize=`grep -w "PIXEL_SIZE" $param|awk '{print $2}'`

echo $Map_mrc
echo $Mask_mrc

#Create map file in BioEM format
#Voxels chosen are those that are wrapped by the mask (also in MRC format)

if [ ! -s map_ROUND1.txt ]; then
./programs/apply_mask.exe <<eot >> aux.log
"$Map_mrc","$Mask_mrc"
"map_ROUND1.txt"
$pixelsize
eot
else
echo "The map_ROUND1.txt already exists"
fi
