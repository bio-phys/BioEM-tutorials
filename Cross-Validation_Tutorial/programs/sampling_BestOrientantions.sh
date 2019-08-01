#!/bin/bash

number_of_orientations_chosen=$1
ANG_PROB=$2
particles_file=$3

if [ ! -f $2 ]; then
    exit 1
fi

awk 'NR>3' $ANG_PROB > tmp
nTotalorientations=`echo "$number_of_orientations_chosen*125"|bc`
nimages=`cat $particles_file|wc -l`
# 
for((w=0;w<$nimages;w++))
do 
 
 awk  '{if($1=='$w')print $2,$3,$4,$5}' tmp|head -$number_of_orientations_chosen > base
 python ./programs/multiply_quat.py 
 name=`sed 's/.*\///g; s/.mrc//g' $particles_file|awk 'NR=='$w'+1{print "ANG_"$1}' `
 echo $nTotalorientations > ./orientations/$name
 awk '{printf"%12.6f%12.6f%12.6f%12.6f\n",$1,$2,$3,$4}' sampling >> ./orientations/$name
done 
 
rm -f base sampling tmp
# Remember tot=125*number of best orientantions chosen... in this case 15
# Remember set goes until 50 because we have 50 thousand images
