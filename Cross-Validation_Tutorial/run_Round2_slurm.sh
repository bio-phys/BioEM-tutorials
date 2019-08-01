#!/bin/bash -l
#SBATCH -J bioem-round2
#SBATCH --partition=express
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --time=00:15:00
#SBATCH --array=1-16


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
x=$SLURM_ARRAY_TASK_ID
# The following line is only needed for the older Slurm versions
SLURM_ARRAY_TASK_COUNT=$((($SLURM_ARRAY_TASK_MAX - $SLURM_ARRAY_TASK_MIN + 1) / $SLURM_ARRAY_TASK_STEP))
ncpus=$SLURM_CPUS_ON_NODE

module purge
module load gcc impi
module load anaconda
module load fftw-serial

export KMP_AFFINITY=compact,granularity=core,1
export OMP_STACKSIZE=120M

mkdir -p ./outputfiles
mkdir -p ./tmp_files

bioem=$1
param=$2
input=$3

######## Extracting parameters and file names ###########

pixelsize=`grep -w "PIXEL_SIZE" $param|awk '{print $2}'`

######## Please run before Write_ListMap.sh to generate List_MapFilter #####

Map_mrc=`awk -v x=$x '{if(NR==x)print $1}' List_MapFilter`
Filt=`awk -v x=$x '{if(NR==x)print $2}' List_MapFilter`

Mask_mrc=`grep -w "MASK" $input|awk '{print $2}'`
ParticlesFile=`grep -w "PARTICLES_FILE" $input|awk '{print $2}'`

filtmap=map_${x}.txt

#Create map file in BioEM format
#Voxels chosen are those that are wrapped by the mask (also in MRC format)

bash Apply_Filter.sh $pixelsize $Filt $Map_mrc $Mask_mrc $x

#############################################

# Running BioEM for each particle in ParticlesFile

true > outputfiles/output_${x}

nparticles=`cat $ParticlesFile | wc -l` # Number of independent particles

w='1'
# Loop over partciles
while [ $w -le $nparticles ]
do

particles_left=$(( ${nparticles} - ${w} + 1))
minn=$(( ${particles_left} < ${ncpus} ? ${particles_left} : ${ncpus} ))

# Loop over CPU cores
for((i=0;i<${minn};i+=1))
do

path_particle=`awk 'NR=='$w'{print $1}' $ParticlesFile`
name_particle=`sed 's/.*\///g; s/.mrc//g' $ParticlesFile|awk 'NR=='$w'{print $1}'`
path_orientations="./orientations/ANG_$name_particle"

# Running BioEM to find best Orientations

OMP_NUM_THREADS=1 GPU=0 BIOEM_DEBUG_OUTPUT=0 BIOEM_ALGO=2 srun --mem 4G -n1 -c1 --exclusive ${bioem}  --Particlesfile $path_particle --Modelfile tmp_files/${filtmap} --OutputFile outputfiles/OUT-${x}-${name_particle} --Inputfile tmp_files/param_${name_particle} --ReadOrientation $path_orientations --ReadMRC &


w=$(( ${w} + 1 ))

done

# Wait for all the processes to finish before entering a new iteration (or finishing completely)
wait
done

# Write the outputs into a single file
for f in outputfiles/OUT-${x}-*
do
echo $f > name-$x
name_particle=`sed 's/outputfiles\/OUT-'"${x}"'-//g' name-$x |awk '{print $1}'`
awk 'NR>5' $f | sed 's/RefMap: 0/RefMap: '${name_particle}'/g' >> outputfiles/output_${x}
rm $f name-$x
done

rm tmp_files/${filtmap}

