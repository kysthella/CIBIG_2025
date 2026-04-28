#!/bin/bash
#SBATCH --job-name=AMR
#SBATCH --output=AMR_%j.out
#SBATCH --error=AMR_%j.err
#SBATCH -p normal
#SBATCH --cpus-per-task=14
#SBATCH --nodelist=node02


INPUT_DIR="/scratch/ky/characterization/clean_entero_cloacae_fasta"
OUTPUT_DIR="/scratch/ky/characterization/results/resfinder_entero"
SPECIES="Enterobacter cloacae complex"

# modules load
module load bioinfo-wave
module load resfinder/4.7.2


mkdir -p $OUTPUT_DIR

echo "Lancement de ResFinder ..."

for fasta in ${INPUT_DIR}/barcode*_entero_cloacae.fasta; do
    
    sample=$(basename "$fasta" _entero_cloacae.fasta)
    
    echo "Traitement en cours : $sample"
    
    
    SAMPLE_OUT="${OUTPUT_DIR}/${sample}"
    mkdir -p "$SAMPLE_OUT"
    
    # Exécution of ResFinder
    
    run_resfinder.py -ifa "$fasta" \
        -o "$SAMPLE_OUT" \
        -s "$SPECIES" \
        --acquired \
        -db_res /scratch/ky/characterization/db_resfinder/resfinder_db \
        -db_disinf /scratch/ky/characterization/db_resfinder/disinfinder_db 
        
done

# resistance aux ammoniums quaternaires
echo "Génération du bilan QAC..."
grep -rEi "qac|sugE|emrE|mdfA" ${OUTPUT_DIR}/*/results_tab.txt > ${OUTPUT_DIR}/bilan_global_qac.txt

echo "Analyse terminée le $(date). Résumé : ${OUTPUT_DIR}/bilan_global_qac.txt"
