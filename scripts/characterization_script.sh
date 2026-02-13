#!/bin/bash

#### SLURM configuration #####
# Define the name  of the job
#SBATCH --job-name=AMR_1
# define the partition to use
#SBATCH -p normal
# define the number of cpu to use
#SBATCH --cpus-per-task=16
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err

#################################
set -euo pipefail                      #######exit on error, undefined variables

####### Definition of the variables for the storagepath, workpath and creation of the directory

STORAGE="storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/FASTQ"
WORKPATH="/data/ky/characterization"
mkdir -p ${WORKPATH}
cd ${WORKPATH}

###########################################
# 
for i in {1..39}
do
    BARCODE=barcode$(printf "%02d" $i)
    FASTQ="SQK-RBK114-96_${BARCODE}.fastq"
    OUTDIR="${WORKPATH}/results/${BARCODE}"
    mkdir -p ${OUTDIR}

    echo "Analysis  $BARCODE"
#Go to path directory
    cd ${OUTDIR}
 
# retreive data from the storage
    rsync -ravz --progress ${STORAGE}/${FASTQ} .

# Quality Control
    module load nanoplot/1.42.0
    NanoPlot --fastq ${FASTQ} -o  qc_report -t 16

# Assembly
    module load flye/2.9.6-b1802
    flye --nano-raw ${FASTQ} -o assembly -t 16

# Polishing
    module load medaka/2.1.1
    medaka_consensus -i ${FASTQ} -d assembly/assembly.fasta -m r1041_e82_400bps_sup_v5.2.0 \
         -o medaka_out -t 16
    
    echo "Analysis $BARCODE completed"
done
echo "Analysis $BARCODE completed"
