#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=14
#SBATCH --mem=40G
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02
#################################

# variables
ASSEMBLY_DIR="/scratch/ky/characterization/all_consensus"
KRAKEN_OUT="/scratch/ky/characterization/results/kraken_results"
mkdir -p "$KRAKEN_OUT"

# modules load
module load bioinfo-wave
module load kraken2/2.17.1  

# Database
KRAKEN_DB="/projects/AMRKY/kraken2_bact_db/"

#  22 barcodes
TARGETS="barcode06 barcode16 barcode20 barcode21 barcode22 barcode23 barcode24 barcode25 barcode26 barcode27 barcode28 barcode29 barcode30 barcode31 barcode32 barcode33 barcode34 barcode35 barcode36 barcode37 barcode38 barcode39"

echo "========= Starting Kraken2 Taxonomic Assignment ========="

for i in $TARGETS
do
    QUERY="${ASSEMBLY_DIR}/${i}.fasta"

    if [ -f "$QUERY" ]; then
        echo "Processing $i..."
        
    
        kraken2 --db "$KRAKEN_DB" \
                --threads 8 \
                --use-names \
                --report "${KRAKEN_OUT}/${i}.k2report" \
                --output "${KRAKEN_OUT}/${i}.kraken" \
                "$QUERY"
        
        echo "Success: Report generated for $i"
    else
        echo "Warning: File $QUERY not found."
    fi
done

echo "Process completed. Check your reports in $KRAKEN_OUT"
