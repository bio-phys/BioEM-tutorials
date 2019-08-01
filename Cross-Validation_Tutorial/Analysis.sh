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

########### Script for analyzing the output from BioEM Round 2 ########

module purge
module load python33/python/3.3 python33/scipy/2015.01

numt=`wc List_MapFilter | awk '{print $1}'`

rm -rf results
mkdir results

for((x=1;x<=$numt;x+=2))
do

y=$(($x+1))

########### Extracting the iteration from the map name #########
########### USING THE RELION FORMAT ############
########### If not using RELION please modify accordingly #######

Map_mrc=`awk -v x=$x '{if(NR==x)print $1}' List_MapFilter`
it=`echo $Map_mrc | sed 's/.*it//' | sed 's/_.*$//'`
Filt=`awk -v x=$x '{if(NR==x)print $2}' List_MapFilter`

grep LogProb: outputfiles/output_$x | awk '{printf"%f\n",$4}' | tail -4 > tmp_files/prob_1
grep LogProb: outputfiles/output_$y | awk '{printf"%f\n",$4}' | tail -4 > tmp_files/prob_2

########### Calculation of the cumulative #########

awk -v filt=$Filt '{a+=$1}END{printf "%f %f\n", 1/filt, a/NR}' tmp_files/prob_1 >> results/CUM_it${it}_half_1
awk -v filt=$Filt '{a+=$1}END{printf "%f %f\n",1/filt, a/NR}' tmp_files/prob_2 >> results/CUM_it${it}_half_2 

########### Calculation of the NJSD #########

njsd=`python programs/calculat_NJSD.py tmp_files/prob_1 tmp_files/prob_2`

awk -v Filt=$Filt -v njsd=$njsd 'BEGIN{printf"%f %f\n",1./Filt,njsd }' >> results/NJSD_it${it}

done
