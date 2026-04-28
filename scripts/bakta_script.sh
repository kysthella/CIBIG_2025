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
#CHECKDB="${WORKPATH}/check_db"
BUSCO="${WORKPATH}/busco_input"
#DB_DIAMOND="/projects/AMRKY/uniref90.dmnd"
#mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
module load bioinfo-wave 
module load bakta/1.12.0 


for i in barcode{20..39}
do
    
    echo "Analysis  $i"
# Annotation
    mkdir -p ${OUTDIR}/${i}/annotation
    BAKTA_DB="/shared/databases/bakta-1.12.0_db/db"
    bakta --db ${BAKTA_DB} \
        --output "${OUTDIR}/${i}/annotation" \
        --prefix "${i}" \
        --locus "${i}_L" \
        --threads 16 \
        --force \
        --keep-contig-headers \
        "${BUSCO}/${i}.fasta"   

    echo "Analysis $i completed"
done

