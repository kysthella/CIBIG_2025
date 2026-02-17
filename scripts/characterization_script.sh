#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=16
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err

#################################
set -euo pipefail                      #######exit on error, undefined variables

####### Definition of the variables for the storagepath, workpath and creation of the directory

STORAGE="storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/FASTQ"
ASSEMBLIES="storage:/projects/AMRKY/assemblies"
WORKPATH="/data/ky/characterization"
#FASTQ="SQK-RBK114-96_barcode$i.fastq"
OUTDIR="${WORKPATH}/results"
mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
module load nanoplot/1.42.0
module load flye/2.9.6
module load medaka/2.1.1

cd ${WORKPATH}
rsync -ravz --progress ${STORAGE} .
for i in {01..39}
do
    mkdir -p $OUTDIR
    echo "Analysis  barcode$i"
    #Go to path directory
    cd $OUTDIR
    mkdir -p barcode$i
    # retreive data from the storage
    # rsync -ravz --progress ${STORAGE}/${FASTQ} .
    # Quality Control
    NanoPlot --fastq ${WORKPATH}/FASTQ/SQK-RBK114-96_barcode$i.fastq -o  barcode$i/qc_report -t 16
    # Assembly
    flye --nano-hq ${WORKPATH}/FASTQ/SQK-RBK114-96_barcode$i.fastq -o barcode$i/assembly -t 16 -g 5m --plasmids
    # Polishing
    medaka_consensus -i ${WORKPATH}/FASTQ/SQK-RBK114-96_barcode$i.fastq \
         -d barcode$i/assembly/assembly.fasta \
         -m r1041_e82_400bps_sup_v5.2.0 \
         -o barcode$i/medaka_out -t 8
    ########Transfert the contigs to the storage
    # rsync -ravz --progress medaka_out/consensus.fasta  ${ASSEMBLIES}/${BARCODE}_contig.fasta

    echo "Analysis barcode$i completed"
done

rsync -ravz --progress barcode$i/medaka_out/consensus.fasta  ${ASSEMBLIES}/barcode$i.contig.fasta
