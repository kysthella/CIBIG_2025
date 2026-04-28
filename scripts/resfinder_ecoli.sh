#!/bin/bash
#SBATCH --job-name=AMR
#SBATCH --output=AMR_%j.out
#SBATCH --error=AMR_%j.err
#SBATCH -p normal
#SBATCH --cpus-per-task=14
#SBATCH --nodelist=node02


INPUT_DIR="/scratch/ky/characterization/clean_ecoli_fasta"
OUTPUT_DIR="/scratch/ky/characterization/results/resfinder_ecoli"
SPECIES="Escherichia coli"

# modules load
module load bioinfo-wave
module load resfinder/4.7.2


mkdir -p $OUTPUT_DIR

echo "Lancement de ResFinder sur les isolats d'E. coli ..."

for fasta in ${INPUT_DIR}/barcode*_Ecoli.fasta; do
    
    sample=$(basename "$fasta" _Ecoli.fasta)
    
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
