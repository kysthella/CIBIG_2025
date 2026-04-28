#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=VC_CLOACAE
#SBATCH -p normal
#SBATCH --cpus-per-task=8
#SBATCH --output=vc_cloacae_%j.out
#SBATCH --error=vc_cloacae_%j.err
#SBATCH --nodelist=node02
#################################

# 1. Variables

REF_CLOACAE="/scratch/ky/characterization/ref_ncbi/Entero_cloacae_1382.fasta"
QUERY_FILE="/scratch/ky/characterization/clean_entero_cloacae_fasta/barcode37_entero_cloacae.fasta"
OUT_DIR="/scratch/ky/characterization/results/variants_cloacae"

mkdir -p "${OUT_DIR}/bam" "${OUT_DIR}/qc" "${OUT_DIR}/vcf"

# 2. Modules
module load bioinfo-wave     
module load minimap2/2.30-r1287
module load samtools/1.19.2
module load bcftools/1.18

# --- STEP 1: Indexing Reference ---
echo "Indexing E. cloacae reference..."
samtools faidx "$REF_CLOACAE"
minimap2 -d "${REF_CLOACAE}.mmi" "$REF_NCBI"

# --- STEP 2: Processing Barcode 37 ---
echo "Processing Barcode 37 (Enterobacter cloacae)..."
BAM_OUT="${OUT_DIR}/bam/barcode37_cloacae.sorted.bam"

# A. Mapping + Sorting
minimap2 -ax asm5 -t 8 "$REF_CLOACAE" "$QUERY_FILE" | \
samtools view -bS - | \
samtools sort -o "$BAM_OUT"

# B. Indexing & QC
samtools index "$BAM_OUT"
samtools flagstat "$BAM_OUT" > "${OUT_DIR}/qc/barcode37.flagstat.txt"
samtools depth "$BAM_OUT" > "${OUT_DIR}/qc/barcode37.depth.txt"

# C. Variant Calling & Filtering (QUAL > 20, no DP filter for assembly)
bcftools mpileup -f "$REF_CLOACAE" "$BAM_OUT" | \
bcftools call -mv -Oz -o "${OUT_DIR}/vcf/barcode37_raw.vcf.gz"

bcftools filter -i "QUAL>20" "${OUT_DIR}/vcf/barcode37_raw.vcf.gz" -Oz -o "${OUT_DIR}/vcf/barcode37_filtered.vcf.gz"
bcftools index -t "${OUT_DIR}/vcf/barcode37_filtered.vcf.gz"

echo "Workflow completed for E. cloacae."

#  Generate a summary table for Enterobacter cloacae (Barcode 37)

cd ${OUT_DIR} 

QC_DIR="qc"
VCF_DIR="vcf"
REPORT="E_cloacae_summary.tsv"

echo -e "Metric\tValue" > $REPORT

# 1. Extract Mapping % from flagstat
MAP_PERC=$(grep "mapped (" ${QC_DIR}/barcode37.flagstat.txt | awk -F'(' '{print $2}' | awk -F'%' '{print $1}')
echo -e "Mapping_Percentage\t${MAP_PERC}%" >> $REPORT

# 2. Calculate Average Depth from depth file
AVG_DEPTH=$(awk '{sum+=$3} END {print sum/NR}' ${QC_DIR}/barcode37.depth.txt)
echo -e "Average_Depth\t${AVG_DEPTH}X" >> $REPORT

# 3. Count High-Quality SNPs
SNP_COUNT=$(bcftools view -H ${VCF_DIR}/barcode37_filtered.vcf.gz | wc -l)
echo -e "Filtered_SNP_Count\t${SNP_COUNT}" >> $REPORT

echo "---------------------------------------"
echo "Summary for E. cloacae (Barcode 37):"
column -t $REPORT
