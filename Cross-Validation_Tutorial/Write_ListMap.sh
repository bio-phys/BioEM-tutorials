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

########## SCRIPT TO WRITE THE LIST OF THE MAP FREQUENCIES #######

param=$1
input=$2

Freqs_sample=`grep -w "NUM_FREQ" $input|awk '{print $2}'`
mapitfile=`grep -w "MAP_ITERATION_FILE" $input|awk '{print $2}'`

pixelsize=`grep -w "PIXEL_SIZE" $param|awk '{print $2}'`
numpix=`grep -w "NUMBER_PIXELS" $param|awk '{print $2}'`

numit=`wc $mapitfile | awk '{print $1}'`

if [ -s List_MapFilter ]
then
echo "FILE List_MapFilter exists. If you want to re-do it please remove it first."
else

####### FREQUENCY RANGE DEFAULT #############
####### Values are in number of pixels ######
fmin=`awk -v numpix=$numpix -v pix=$pixelsize 'BEGIN{print 1./numpix/pix}' `
fmax=`awk -v pix=$pixelsize 'BEGIN{print 0.5*2./3./pix}' `

for((it=1;it<=$numit;it++))
do
name=`awk -v it=$it 'NR==it' $mapitfile`
  for((nf=1;nf<=$Freqs_sample;nf++))
   do
   for half in 1 2
    do
     infrq=`awk -v fmin=$fmin -v fmax=$fmax -v f=$nf -v fs=$Freqs_sample 'BEGIN{print 1/(f*(fmax-fmin)/fs+fmin)}'`
     echo ${name}_half${half}_class001.mrc $infrq >> List_MapFilter
     done
   done
done

echo "Successful creation of List_MapFilter file"
fi
