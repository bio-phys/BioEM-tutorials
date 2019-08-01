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


param=$1
input=$2

mkdir -p ./tmp_files

ParticlesFile=`grep -w "PARTICLES_FILE" $input|awk '{print $2}'`

nparticles=`cat $ParticlesFile | wc -l` # Number of independent particles

for((w=1;w<=$nparticles;w+=1))
do

name_particle=`sed 's/.*\///g; s/.mrc//g' $ParticlesFile|awk 'NR=='$w'{print $1}'`

def=`awk 'NR=='$w'{print $2}' $ParticlesFile`

awk -v x=$def '{if($1=="CTF_DEFOCUS"){print $1,x,x,1}
                else{if($1=="PRIOR_DEFOCUS_CENTER"){print $1,x}
			else{if($1!="WRITE_PROB_ANGLES"){
			     if($1=="SIGMA_PRIOR_DEFOCUS"){print $1,0.3}else {print $0}}}}}' $param > tmp_files/param_$name_particle
done

echo "Successful creation of tmp_files directory with param_particle-names"
