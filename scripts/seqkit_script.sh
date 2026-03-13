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
#mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
#module load nanoplot/1.42.0
#module load flye/2.9.6
#module load medaka/2.1.1
module load seqkit/2.11.0
module load python/3.12.6 

#cd ${WORKPATH}
#rsync -ravz --progress ${STORAGE} .
for i in barcode{01..39}
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
    echo "========= check $i ========= \n"
    seqkit stats ${FASTQ}/*_${i}.fastq > ${OUTDIR}/${i}/seqkit_stats.txt
    
 # Vérification : si le fichier créé est vide, on affiche une alerte
    if [ ! -s ${OUTDIR}/${i}/seqkit_stats.txt ]; then
        echo "ALERTE : Seqkit n'a rien trouvé pour $i dans ${FASTQ}"
    fi
    echo "check  $i completed"
done

echo "Génération du tableau récapitulatif..."

python3 << EOF
import os
import glob
import re

base_dir = "${OUTDIR}"
output_file = "${WORKPATH}/summary_seqkit_final.csv"

# Trouver les fichiers
files = sorted(glob.glob(os.path.join(base_dir, "barcode*", "seqkit_stats.txt")))

with open(output_file, 'w') as fout:
    header_written = False
    
    for f in files:
        barcode_name = os.path.basename(os.path.dirname(f))
        try:
            with open(f, 'r') as fin:
                lines = fin.readlines()
                # On cherche la ligne qui commence par le nom du fichier (données)
                # et la ligne qui commence par 'file' (en-tête)
                header_line = ""
                data_line = ""
                
                for line in lines:
                    if line.startswith("file"):
                        header_line = line.strip()
                    elif ".fastq" in line:
                        data_line = line.strip()
                
                if not header_line or not data_line:
                    continue

                # FONCTION MIRACLE : On remplace les espaces multiples par une virgule
                # MAIS on supprime d'abord les virgules et espaces à l'intérieur des nombres (ex: 8,673,362 -> 8673362)
                def clean_line(text):
                    text = text.replace(",", "") # Enlever les virgules de formatage
                    return ",".join(re.split(r'\s{2,}', text)) # Couper uniquement sur les grands espaces (>=2)

                if not header_written:
                    fout.write("sample_id," + clean_line(header_line) + "\n")
                    header_written = True
                
                fout.write(barcode_name + "," + clean_line(data_line) + "\n")
                
        except Exception as e:
            print(f"Erreur sur {barcode_name}: {e}")

print(f"Terminé. Tableau disponible ici : {output_file}")
EOF

