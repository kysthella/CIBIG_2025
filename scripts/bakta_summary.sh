#!/bin/bash


#  Extract genomic features from Bakta .txt summary files

ANNOT_DIR="/scratch/ky/characterization/results"
OUTPUT_FILE="bakta_summary_report.tsv"

# Initialize header
echo -e "Barcode\tSize_bp\tCDS_Count\trRNA_Count\ttRNA_Count" > "$OUTPUT_FILE"

# Loop through all 39 barcodes
for i in {01..39}
do
    # Path to the .txt file 
    FILE="${ANNOT_DIR}/barcode${i}/annotation/barcode${i}.txt"
    
    if [ -f "$FILE" ]; then
        # Standard Bakta parsing
        SIZE=$(grep "Length:" "$FILE" | awk '{print $2}')
        CDS=$(grep "CDSs:" "$FILE" | awk '{print $2}')
        RRNA=$(grep "rRNAs:" "$FILE" | awk '{print $2}')
        TRNA=$(grep "tRNAs:" "$FILE" | awk '{print $2}')
        
        echo -e "barcode${i}\t${SIZE}\t${CDS}\t${RRNA}\t${TRNA}" >> "$OUTPUT_FILE"
    else
        # Log empty/failed annotations
        echo "[WARNING] No Bakta results for barcode${i}" >&2
        echo -e "barcode${i}\t0\t0\t0\t0" >> "$OUTPUT_FILE"
    fi
done

echo "Summary generated: $OUTPUT_FILE"
column -t "$OUTPUT_FILE"
