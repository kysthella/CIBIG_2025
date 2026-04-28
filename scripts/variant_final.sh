#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_2
#SBATCH -p normal
#SBATCH --cpus-per-task=10
#SBATCH --output=AMR_2_%j.out
#SBATCH --error=AMR_2_%j.err
#SBATCH --nodelist=node02
#################################

# 1. Définition des Variables
REF_NCBI="/scratch/ky/characterization/ref_ncbi/E_coli_K12.fasta"
QUERY_DIR="/scratch/ky/characterization/clean_ecoli_fasta"
OUT_DIR="/scratch/ky/characterization/results/final_variant"

mkdir -p "${OUT_DIR}/bam" "${OUT_DIR}/qc" "${OUT_DIR}/vcf"

#   Modules
module load bioinfo-wave 
module load minimap2/2.30-r1287
module load samtools/1.19.2
module load bcftools/1.18

#  Indexation de la Référence NCBI
echo "========= Indexing Reference ========="
samtools faidx "$REF_NCBI"
minimap2 -d "${REF_NCBI}.mmi" "$REF_NCBI"


TARGETS="barcode22 barcode26 barcode30 barcode35 barcode38 barcode39"

for i in $TARGETS
do
    echo "Processing : $i"
    
    INPUT_FASTA="${QUERY_DIR}/${i}_Ecoli.fasta"
    BAM_OUT="${OUT_DIR}/bam/${i}.sorted.bam"

    if [ -f "$INPUT_FASTA" ]; then
        
        #  Mapping + Conversion + Sorting 
        echo "[1/6] Mapping and Sorting..."
        minimap2 -ax asm5 -t 10 "$REF_NCBI" "$INPUT_FASTA" | \
        samtools view -bS - | \
        samtools sort -o "$BAM_OUT"
        
        #  Indexation du BAM 
        echo "[2/6] Indexing BAM..."
        samtools index "$BAM_OUT"

        #  QC Mapping (Flagstat & Depth)
        echo "[3/6] Generating QC Stats..."
        samtools flagstat "$BAM_OUT" > "${OUT_DIR}/qc/${i}.flagstat.txt"
        samtools depth "$BAM_OUT" > "${OUT_DIR}/qc/${i}.depth.txt"

        #  Variant Calling (Mpileup & Call)
        echo "[4/6] Variant Calling (Raw)..."
        bcftools mpileup -f "$REF_NCBI" "$BAM_OUT" | \
        bcftools call -mv -Oz -o "${OUT_DIR}/vcf/${i}.raw.vcf.gz"

        #  Double Filtrage  (QUAL > 30 PUIS DP > 10)
        
        echo "[5/6] Quality Filtering (QUAL>30 & DP>10)..."
        bcftools filter -i "QUAL>20" ${i}.raw.vcf.gz -Oz -o ${i}.filtered.vcf.gz
        
        
        #  Indexation du VCF final
        echo "[6/6] Indexing Final VCF..."
        bcftools index -t "${OUT_DIR}/vcf/${i}.filtered.vcf.gz"

        echo ">>> Success: $i processing completed."
    else
        echo ">>> Error: $INPUT_FASTA not found."
    fi
done

echo "========= Workflow Finished. Results in $OUT_DIR ========="

####Decompte du nombre de SNP
cd ${OUT_DIR}
echo -e "Isolate_ID\tSNP_Count" > final_snp_report.tsv
for i in barcode22 barcode26 barcode30 barcode35 barcode38 barcode39
do
    COUNT=$(bcftools view -H ${i}.filtered.vcf.gz | wc -l)
    echo -e "${i}\t${COUNT}" >> final_snp_report.tsv
done

# Afficher le résultat
column -t final_snp_report.tsv

