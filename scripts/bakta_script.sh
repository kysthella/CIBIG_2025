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
#module load nanoplot/1.42.0
#module load flye/2.9.6
#module load medaka/2.1.1
#module load checkm2/1.1.0
#module load busco/6.0.0
#module load singularity/4.0.1
#module load diamond/2.0.9
module load python/3.12.6 
module load bakta/1.10.3 
#cd ${WORKPATH}
#rsync -ravz --progress ${STORAGE} .
for i in barcode{20..39}
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
    #echo "========= Assembly $i ========= \n"
    #flye --meta --nano-hq \
     #   ${FASTQ}/*${i}.fastq \
      #  -o ${OUTDIR}/${i}/assembly/ -t 16 

   # if [ $? -ne 0 ]; then
    #    echo "ATTENTION : L'assemblage du barcode$i a échoué, passage au suivant..."
    #else
     #   echo "Succès pour le $i."
   # fi
#CHECKM
    #cp ${OUTDIR}/${i}/assembly/assembly.fasta ${WORKPATH}/check_input/${i}.fasta
#    checkm2 database --download --path ${CHECKDB}
 #   mkdir -p ${OUTDIR}/${i}/assembly/checkm2_results 
    #CHECKOUT="${OUTDIR}/${i}/assembly/checkm2_results"
   # checkm2 predict \
     #   --threads 16 \
    #    --input ${WORKPATH}/check_input \
   #     --output-directory ${CHECKOUT}/ \
  #      --extension .fasta \
 #       --database_path ${CHECKDB}/CheckM2_database/uniref100.KO.1.dmnd \
#        --force

#POLISHING
   #medaka_consensus -i ${FASTQ}/*${i}.fastq \
    #     -d ${OUTDIR}/${i}/assembly/assembly.fasta \
     #    -m r1041_e82_400bps_sup_v5.2.0 \
      #   -o ${OUTDIR}/${i}/polishing/ -t 16



#BUSCO
 #   cp ${OUTDIR}/${i}/polishing/consensus.fasta ${WORKPATH}/busco_input/${i}.fasta
  #  mkdir -p ${OUTDIR}/${i}/polishing/busco_out
   # OUT="${OUTDIR}/${i}/polishing/busco_out"

    #busco -i "$BUSCO" \
     #   -o "busco_${i}" \
      #  -m genome \
       # -l bacteria_odb10 \
        #-c 16 \
       # --out_path "$OUT" \
        #--force 

## Taxonomic assignment
    #singularity exec \
        #--bind ${WORKPATH}:${WORKPATH} \
        #/usr/local/bioinfo/containers/diamond-2.0.9.sif \
        #diamond blastx \
       # -d "${DB_DIAMOND}" \
      #  -q "${OUTDIR}/${i}/polishing/consensus.fasta" \
     #   -o "${OUTDIR}/${i}/taxonomy_diamond.tsv" \
    #    --outfmt 6 qseqid sseqid pident length evalue bitscore stitle \
   #     --threads 16 \
  #      --max-target-seqs 1 \
 #       --evalue 1e-5 \
#        --id 60
    #cp -r ${OUTDIR}/${i}/taxonomy_diamond.tsv /projects/AMRKY/assignation_diamond/${i}.tsv

# Annotation
    #mkdir -p ${OUTDIR}/${i}/annotation
    BAKTA_DB="${WORKPATH}/bakta_db/db-light/db-light"
    bakta --db ${BAKTA_DB} \
        --output "${OUTDIR}/${i}/annotation" \
        --prefix "${i}" \
        --locus "${i}_L" \
        --threads 16 \
        --force \
        --keep-contig-headers \
        "${BUSCO}/${i}.fasta"   
 ########Transfert the contigs to the storage
    # rsync -ravz --progress medaka_out/consensus.fasta  ${ASSEMBLIES}/${BARCODE}_contig.fasta

    echo "Analysis $i completed"
done

#rsync -ravz --progress barcode$i/medaka_out/consensus.fasta  ${ASSEMBLIES}/barcode$i.contig.fasta
