#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=10
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02

#  Paths
BASE_DIR="/scratch/ky/characterization"
INPUT_FASTA="${BASE_DIR}/all_consensus"
RESULTS_DIR="${BASE_DIR}/results"
CLEAN_OUT="${BASE_DIR}/clean_ecoli_fasta"

mkdir -p "$CLEAN_OUT"
# Module load
module load bioinfo-wave
module load seqkit/2.11.0
 
#  barcodes validés
TARGETS="barcode6 barcode16 barcode20 barcode21 barcode22 barcode23 barcode24 barcode25 barcode26 barcode27 barcode28 barcode29 barcode30 barcode31 barcode32 barcode33 barcode34 barcode35 barcode36 barcode37 barcode38 barcode39"

echo "========= Début de l'Extraction Automatisée d'E. coli ========="

for i in $TARGETS
do
   
    TSV_FILE="${RESULTS_DIR}/${i}/taxonomy_diamond.tsv"
    FASTA_FILE="${INPUT_FASTA}/${i}.fasta"

    if [ -f "$TSV_FILE" ] && [ -f "$FASTA_FILE" ]; then
        echo "Traitement de $i..."
        
        #  Extraire l'ID du contig (colonne 1) si la ligne contient 'Escherichia coli'
        grep "Escherichia coli" "$TSV_FILE" | cut -f1 | sort | uniq > "${CLEAN_OUT}/${i}_list.txt"
        
        #  Extraire ces séquences du FASTA original avec SeqKit
        if [ -s "${CLEAN_OUT}/${i}_list.txt" ]; then
            seqkit grep -f "${CLEAN_OUT}/${i}_list.txt" "$FASTA_FILE" -o "${CLEAN_OUT}/${i}_Ecoli.fasta"
            
           # nombre de contigs extraits
            COUNT=$(wc -l < "${CLEAN_OUT}/${i}_list.txt")
            echo "Succès : $COUNT contig(s) E. coli extrait(s) pour $i"
        else
            echo "Attention : Aucun contig E. coli trouvé dans le rapport de $i"
        fi
        
        # Nettoyage du fichier temporaire de liste
        rm "${CLEAN_OUT}/${i}_list.txt"
    else
        echo "Erreur : Fichiers manquants pour $i (Vérifie les chemins)"
    fi
done

echo "Extraction terminée. Les fichiers propres sont dans : $CLEAN_OUT"
