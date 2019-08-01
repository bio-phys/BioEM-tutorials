#$ -S /bin/bash
#$ -cwd
#$ -N bioem-test-array
#$ -l h_rt=00:30:00
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

# Local ID of the job
x=$SGE_TASK_ID
SGE_TASK_COUNT=$((($SGE_TASK_LAST - $SGE_TASK_FIRST + 1) / $SGE_TASK_STEPSIZE))
ncpus=24

module purge
module load intel impi cuda
module load python33/python/3.3 python33/scipy/2015.10
module load fftw/gcc/3.3.4

export KMP_AFFINITY=compact,granularity=core,1
export OMP_STACKSIZE=120M

mkdir -p ./outputfiles
mkdir -p ./tmp_files

BIOEM=$1
param=$2
input=$3


########## Extracting parameters and file names ###########

pixelsize=`grep -w "PIXEL_SIZE" $param|awk '{print $2}'`

######## Please run before Write_listMap.sh to generate List_MapFilter #####
beg=$4
end=$5

for((x=$beg;x<$end;x++))
do

echo $x
Map_mrc=`awk -v x=$x '{if(NR==x)print $1}' List_MapFilter`
Filt=`awk -v x=$x '{if(NR==x)print $2}' List_MapFilter`

Mask_mrc=`grep -w "MASK" $input|awk '{print $2}'`
ParticlesFile=`grep -w "PARTICLES_FILE" $input|awk '{print $2}'`

filtmap=map_${x}.txt

#Create map file in BioEM format
#Voxels chosen are those that are wrapped by the mask (also in MRC format)

bash Apply_Filter.sh $pixelsize $Filt $Map_mrc $Mask_mrc $x

#############################################

#Running BioEM for each paricle in ParticlesFile

#true > outputfiles/output_${x}

nparticles=`cat $ParticlesFile | wc -l` #Number of independent paricles

for((w=1;w<=$nparticles;w+=1))
do

path_particle=`awk 'NR=='$w'{print $1}' $ParticlesFile`
name_particle=`sed 's/.*\///g; s/.mrc//g' $ParticlesFile|awk 'NR=='$w'{print $1}'`
path_orientations="./orientations/ANG_$name_particle"

#RUN BioEM to find best Orientations

# Running BioEM
OMP_NUM_THREADS=12 GPU=1 GPUDEVICE=-1 BIOEM_DEBUG_OUTPUT=0 BIOEM_ALGO=2 mpiexec -perhost 2 ${BIOEM}  --Particlesfile $path_particle --Modelfile tmp_files/${filtmap} --OutputFile outputfiles/OUT-${x} --Inputfile tmp_files/param_${name_particle} --ReadOrientation $path_orientations  --ReadMRC
awk 'NR>5' outputfiles/OUT-${x} | sed 's/RefMap: 0/RefMap: '$name_particle'/g' >> outputfiles/output_${x}

rm outputfiles/OUT-${x}

done

rm tmp_files/${filtmap}

done


