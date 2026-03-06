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
#mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
#module load nanoplot/1.42.0
module load flye/2.9.6
#module load medaka/2.1.1

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
    #NanoPlot --fastq ${FASTQ}/*${i}.fastq -o ${OUTDIR}/${i}/qc_report/ -t 16
    # Assembly
    echo "========= Assembly $i ========= \n"
    flye --meta --nano-hq \
        ${FASTQ}/*${i}.fastq \
        -o ${OUTDIR}/${i}/assembly/ -t 16 

    if [ $? -ne 0 ]; then
        echo "ATTENTION : L'assemblage du barcode$i a échoué, passage au suivant..."
    else
        echo "Succès pour le $i."
    fi
    # Polishing
    #medaka_consensus -i ${FASTQ}/*${i}.fastq \
     #    -d ${OUTDIR}/${i}/assembly/assembly.fasta \
      #   -m r1041_e82_400bps_sup_v5.2.0 \
      #   -o ${OUTDIR}/${i}/polishing/ -t 16
    ########Transfert the contigs to the storage
    # rsync -ravz --progress medaka_out/consensus.fasta  ${ASSEMBLIES}/${BARCODE}_contig.fasta

    echo "Analysis $i completed"
done

#rsync -ravz --progress barcode$i/medaka_out/consensus.fasta  ${ASSEMBLIES}/barcode$i.contig.fasta
