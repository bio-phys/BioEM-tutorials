#!/bin/bash -l
#SBATCH -J bioem-round1
#SBATCH --partition=gpu
#SBATCH --constraint="gpu"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=16
#SBATCH --time=01:00:00

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
module load anaconda
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
