#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=16
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02
#################################
#set -euo pipefail                      #######exit on error, undefined variables

####### Definition of the variables for the storagepath, workpath and creation of the directory
#STORAGE="storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/FASTQ"
#ASSEMBLIES="storage:/projects/AMRKY/assemblies"
WORKPATH="/scratch/ky/characterization"
FASTQ="${WORKPATH}/FASTQ"
OUTDIR="${WORKPATH}/results"
CHECKDB="${WORKPATH}/check_db"
#mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
#module load nanoplot/1.42.0
#module load flye/2.9.6
#module load medaka/2.1.1
module load checkm2/1.1.0 
#cd ${WORKPATH}
#rsync -ravz --progress ${STORAGE} .
for i in barcode{01..39}
do
    #mkdir -p $OUTDIR
    echo "Analysis  $i"
    #Go to path directory
    #cd $OUTDIR
    #mkdir -p barcode$i
    # retreive data from the storage
    # rsync -ravz --progress ${STORAGE}/${FASTQ} .
    # Quality Control
    #NanoPlot --fastq ${WORKPATH}/FASTQ/SQK-RBK114-96_barcode$i.fastq -o  barcode$i/qc_report -t 16
    # Assembly
#    echo "========= Assembly $i ========= \n"
 #   flye --meta --nano-hq \
 #       ${FASTQ}/*${i}.fastq \
  #      -o ${OUTDIR}/${i}/assembly/ -t 16 

#CHECKM
    #cp ${OUTDIR}/${i}/assembly/assembly.fasta ${WORKPATH}/check_input/${i}.fasta
#    checkm2 database --download --path ${CHECKDB}
    mkdir -p ${OUTDIR}/${i}/assembly/checkm2_results 
    CHECKOUT="${OUTDIR}/${i}/assembly/checkm2_results"
    checkm2 predict \
        --threads 16 \
        --input ${WORKPATH}/check_input \
        --output-directory ${CHECKOUT}/ \
        --extension .fasta \
        --database_path ${CHECKDB}/CheckM2_database/uniref100.KO.1.dmnd \
        --force
done
