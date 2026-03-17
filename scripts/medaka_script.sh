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
#CHECKDB="${WORKPATH}/check_db"


###########################################
##### Modules load
#module load seqkit/2.11.0
#module load python/3.12.6
#module load nanoplot/1.42.0
#module load flye/2.9.6 
#module load checkm2/1.1.0
module load medaka/2.1.1


for i in barcode{01..39}
do

    # Seqkit
   # echo "========= check $i ========= \n"
    #seqkit stats ${FASTQ}/*_${i}.fastq > ${OUTDIR}/${i}/seqkit_stats.txt

    #if [ ! -s ${OUTDIR}/${i}/seqkit_stats.txt ]; then
        #echo "ALERTE : Seqkit n'a rien trouvé pour $i dans ${FASTQ}"
    #fi
    #echo "check  $i completed"
#done

#echo "Génération du tableau récapitulatif..."

##python3 << EOF
import os
import glob
import re

base_dir = "${OUTDIR}"
output_file = "${WORKPATH}/summary_seqkit_final.csv"

# find files
files = sorted(glob.glob(os.path.join(base_dir, "barcode*", "seqkit_stats.txt")))

with open(output_file, 'w') as fout:
    header_written = False

    for f in files:
        barcode_name = os.path.basename(os.path.dirname(f))
        try:
            with open(f, 'r') as fin:
                lines = fin.readlines()
                header_line = ""
                data_line = ""

                for line in lines:
                    if line.startswith("file"):
                        header_line = line.strip()
                    elif ".fastq" in line:
                        data_line = line.strip()

                if not header_line or not data_line:
                    continue

                def clean_line(text):
                    text = text.replace(",", "") # Enlever les virgules de formatage
                    return ",".join(re.split(r'\s{2,}', text))

                if not header_written:
                    fout.write("sample_id," + clean_line(header_line) + "\n")
                    header_written = True

                fout.write(barcode_name + "," + clean_line(data_line) + "\n")

        except Exception as e:
            print(f"Erreur sur {barcode_name}: {e}")

print(f"Terminé. Tableau disponible ici : {output_file}")
##EOF

    
# Quality Control
    #NanoPlot --fastq ${WORKPATH}/FASTQ/*${i}.fastq -o ${OUTDIR}/qc_report -t 16

 # Assembly
    #echo "========= Assembly $i ========= \n"
    "flye --meta --nano-hq \
      #  ${FASTQ}/*${i}.fastq \
     #   -o ${OUTDIR}/${i}/assembly/ -t 16

    #if [ $? -ne 0 ]; then
     #   echo "ATTENTION : L'assemblage du barcode$i a échoué, passage au suivant..."
    #else
     #   echo "Succès pour le $i."
    #fi
    
    #echo "Analysis $i completed"

#CHECKM
    #cp ${OUTDIR}/${i}/assembly/assembly.fasta ${WORKPATH}/check_input/${i}.fasta
    #checkm2 database --download --path ${CHECKDB}
    #mkdir -p ${OUTDIR}/${i}/assembly/checkm2_results
    #CHECKOUT="${OUTDIR}/${i}/assembly/checkm2_results"
    #checkm2 predict \
     #   --threads 16 \
      #  --input ${WORKPATH}/check_input \
       # --output-directory ${CHECKOUT}/ \
        #--extension .fasta \
        #--database_path ${CHECKDB}/CheckM2_database/uniref100.KO.1.dmnd \
        #--force

 # Polishing
    medaka_consensus -i ${FASTQ}/*${i}.fastq \
         -d ${OUTDIR}/${i}/assembly/assembly.fasta \
         -m r1041_e82_400bps_sup_v5.2.0 \
         -o ${OUTDIR}/${i}/polishing/ -t 16
    
    echo "Analysis $i completed"
done




