#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=10
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02

#Module load
module load bioinfo-wave
module load seqkit/2.11.0

#  Configuration 
SPECIES="Enterobacter cloacae"

SHORT_NAME="entero_cloacae"

#  Chemins
BASE_DIR="/scratch/ky/characterization"
INPUT_FASTA="${BASE_DIR}/all_consensus"
RESULTS_DIR="${BASE_DIR}/results"
# On crée un dossier spécifique pour chaque espèce
CLEAN_OUT="${BASE_DIR}/clean_${SHORT_NAME}_fasta"

mkdir -p "$CLEAN_OUT"

#  Liste des 22 barcodes
TARGETS="barcode6 barcode16 barcode20 barcode21 barcode22 barcode23 barcode24 barcode25 barcode26 barcode27 barcode28 barcode29 barcode30 barcode31 barcode32 barcode33 barcode34 barcode35 barcode36 barcode37 barcode38 barcode39"

echo "========= Extraction de : $SPECIES ========="

for i in $TARGETS
do
    TSV_FILE="${RESULTS_DIR}/${i}/taxonomy_diamond.tsv"
    FASTA_FILE="${INPUT_FASTA}/${i}.fasta"

    if [ -f "$TSV_FILE" ] && [ -f "$FASTA_FILE" ]; then
        
        # Extraction des ID des contigs correspondant à l'espèce choisie
        grep "$SPECIES" "$TSV_FILE" | cut -f1 | sort | uniq > "${CLEAN_OUT}/${i}_list.txt"
        
       	if [ -s "${CLEAN_OUT}/${i}_list.txt" ]; then
            seqkit grep -f "${CLEAN_OUT}/${i}_list.txt" "$FASTA_FILE" -o "${CLEAN_OUT}/${i}_${SHORT_NAME}.fasta"
            
            SIZE=$(ls -lh "${CLEAN_OUT}/${i}_${SHORT_NAME}.fasta" | awk '{print $5}')
            echo "Succès : $i -> ${SHORT_NAME} extrait ($SIZE)"
        fi
	rm -f "${CLEAN_OUT}/${i}_list.txt"
    fi
done

echo "Extraction terminée pour $SPECIES. Résultats dans $CLEAN_OUT"
