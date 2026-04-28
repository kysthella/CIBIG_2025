#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=plasmid
#SBATCH -p normal
#SBATCH --cpus-per-task=4
#SBATCH --output=plasmid_%j.out
#SBATCH --error=plasmid_%j.err
#SBATCH --nodelist=node02
#################################


module load bioinfo-wave
module load mob_suite/3.1.9


OUTDIR="/scratch/ky/characterization/results/plasmid_enterica"

mkdir -p $OUTDIR


for file in clean_s_enterica_fasta/barcode*_s_enterica.fasta; do
    
    name=$(basename "$file" _s_enterica.fasta)
    echo "Analyse de $name en cours..."
    
    
    mob_recon --infile "$file" --outdir "$OUTDIR/mob_results_${name}" --force
done
