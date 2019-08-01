### run in /bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N bioem-round1
#$ -l h_rt=00:29:00
### Allocating nodes with 2 GPUs each, on "phys" cluster
#$ -pe impi_hydra 24
#$ -P gpu
#$ -l use_gpus=1
#$ -l type_gpus=gtx1080

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

module purge
module load intel impi cuda
module load python33/python/3.3 python33/scipy/2015.10
export KMP_AFFINITY=compact,granularity=core,1
#export GPUWORKLOAD=100
export BIOEM_DEBUG_OUTPUT=0

mkdir -p ./outputfiles
mkdir -p ./orientations

bioem=$1
param=$2
input=$3

ParticlesFile=`grep -w "PARTICLES_FILE" $input|awk '{print $2}'`
OrientFile=`grep -w "ORIENT_FILE" $input|awk '{print $2}'`

awk '{print $1}' $ParticlesFile > tmp_parfile

###### Running BioEM to find best Orientations ###

OMP_NUM_THREADS=12 GPU=1 GPUDEVICE=-1 BIOEM_DEBUG_OUTPUT=0 BIOEM_ALGO=1 mpiexec -perhost 2 ${bioem} --Particlesfile tmp_parfile --Modelfile map_ROUND1.txt --OutputFile outputfiles/Output_Round1.txt  --Inputfile $param --ReadOrientation $OrientFile  --ReadMRC --ReadMultipleMRC 
mv ANG_PROB ./orientations/ANG_PROB_ROUND1

# Make grid around best orientations
number_of_orientations_chosen=`grep -w "WRITE_PROB_ANGLES" $param|awk '{print $2}'`
bash programs/sampling_BestOrientantions.sh $number_of_orientations_chosen orientations/ANG_PROB_ROUND1 $ParticlesFile
rm tmp_parfile
