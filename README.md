# Certificat International en Bioinformatique et Génomique (CIBiG_2025)
# Bioinformatic tutored project
## Overview
This README provides comprehensive information about a practical training course in Bioinformatics and Genomics, aligned with the International Certificate in Bioinformatics and Genomics (CIBiG). The course takes place in Abidjan, Côte d'Ivoire, as part of the Central and West African Virus Epidemiology (WAVE) initiative.
## Project duration
**January 15th - March 27th 2026**

## Authors
**Nènè Sthella KY**
# Tutors
- **Ezechiel Bionimian TIBIRI** (WAVE)
- **Edith NIKIEMA** (INERA)
- **Faizatou SORGHO** (IRSS/URCN)

## Objectives
The primary aim of this tutored project is to provide hands-on training in bioinformatics techniques and applications, focusing on genomic data analysis and interpretation. Participants will engage in practical exercises, collaborative projects, and discussions led by the tutors.

## Expective outcomes
Participants will gain:
- Proficiency in bioinformatics tools and software.
- Skills in genomic data analysis.
- Understanding of the role of bioinformatics.
- Collaboration experience with professionals in the field.

## Contact Information
For further inquiries or information about the project, please contact the tutors or project partners:
- **Ezechiel Bionimian TIBIRI** [ezechiel.tibiri@wave-center.org]
- **Nènè Sthella KY** [kynenepharm@gmail.com]
- **Marguerite Edith NIKIEMA** [edith.nikiema@ujkz.bf]
- **Faizatou SORGHO** [sorghofaiza@gmail.com]

## Project theme
Study of diversity and antimicrobial resistance profile of bacteria isolated from pus and pyuria samples from patients
at the HOSCO and SCHIPHRA Hospital in Burkina Faso

### General objective
To study the diversity and antimicrobial resistance profile of isolates from pus and pyuria samples collected from patients 
### Specific objectives
- Assemble and characterize the obtained genomes
- Identify resistance mechanisms
- Determine the antimicrobial resistance profile of the isolates
- Perform simulation, modeling, and prediction analyses based on the results obtained
 
## Mind mapp
Access(https://mm.tt/map/3908788964?t=HBmBdwM2Wu)

This mind map summarizes in one image all the reflections made around our theme. It enabled us to better understand the subject we were given, then define the different approaches to analysis and rendering. It includes:
- Thematic and objectives
- Analysis design
- Bibliographic synthesis
- Available ressources 
- Ressources to look for 
- Restitution & Reproducibility

## Bioinformatic strategy
The entire bioinformatics strategy was carried out in several stages.
 Access the workflow(https://drive.google.com/file/d/1NsHUucNadxrgZTGWEANmvWyp1G_1sTRz/view?usp=drive_link)

### 1. Data acquisition
All work or bioinformatics strategy was carried out on the WAVE cluster 
The first step before executing the scripts was 

* to connect to the cluster on the terminal via the login

```bash
ssh login@160.120.108.164
```

* Connect to a node on a specific partition according to the analyses
x = partition
y = number of cpus
```bash
srun -p x -c y --pty bash -i
```
* The data directory "AMRKY" was created by the tutors in a shared directory on the storage  "/projects"

* The name of the raw data directory from the sequencing was named "FASTQ_WGS_LABIOGENE"

* Create the “ky” working directory in the “scratch” directory and move around in it

```bash
mkdir -p /scratch/ky
cd /scratch/ky
```

* Create the working subdirectory "characterization"
```bash
mkdir -p /scratch/ky/characterization
cd /scratch/ky/characterization
```

* Create the results subdirectory "results"
```bash
mkdir -p /scratch/ky/characterization/results
```

* Copy the raw data from the storage to the workpath
```bash
cd /scratch/ky/characterization
mkdir -p /scratch/ky/characterization/FASTQ
rsync -avz --progress storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/*.fastq ./FASTQ
```  

### 2. Raw data quality control
#### 2.1.  SeqKit Stats
* Initial assessment of raw Nanopore reads to obtain global statistics (read counts, total bases, N50, and length distribution).
[Access seqkit_script.sh](/scripts/seqkit_script.sh)

```bash
#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=16
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02
#################################
set -euo pipefail                      #######exit on error, undefined variables

####### Definition of the variables for the storagepath, workpath and creation of the directory

#STORAGE="storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/FASTQ"
#ASSEMBLIES="storage:/projects/AMRKY/assemblies"
WORKPATH="/scratch/ky/characterization"
FASTQ="${WORKPATH}/FASTQ"
OUTDIR="${WORKPATH}/results"
###########################################
##### Modules load
module load seqkit/2.11.0
module load python/3.12.6

##############################
for i in barcode{01..39}
do

    echo "Analysis  $i"

    # Seqkit
    echo "========= check $i ========= \n"
    seqkit stats ${FASTQ}/*_${i}.fastq > ${OUTDIR}/${i}/seqkit_stats.txt

    if [ ! -s ${OUTDIR}/${i}/seqkit_stats.txt ]; then
        echo "ALERTE : Seqkit n'a rien trouvé pour $i dans ${FASTQ}"
    fi
    echo "check  $i completed"
done
```
Run the script
```bash
sbatch seqkit_script.sh
```

* Generating Seqkit summary table
[Access seqkit_graph.py](/scripts/seqkit_graph.py)

```bash
python3 << EOF
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
EOF             
```


#### 2.2. NanoPlot QC
High-resolution quality control visualization to evaluate read length vs. read quality (Q-score) and identify potential sequencing biases.
[Access nanoplot_script.sh](/scripts/nanoplot_script.sh)

```bash
#!/bin/bash
#### SLURM configuration #####
#SBATCH --job-name=AMR_1
#SBATCH -p normal
#SBATCH --cpus-per-task=16
#SBATCH --output=AMR_1_%j.out
#SBATCH --error=AMR_1_%j.err
#SBATCH --nodelist=node02
#################################
set -euo pipefail                      #######exit on error, undefined variables

####### Definition of the variables for the storagepath, workpath and creation of the directory

#STORAGE="storage:/projects/AMRKY/FASTQ_WGS_LABIOGENE/FASTQ"
#ASSEMBLIES="storage:/projects/AMRKY/assemblies"
WORKPATH="/scratch/ky/characterization"
FASTQ="${WORKPATH}/FASTQ"
OUTDIR="${WORKPATH}/results"

###########################################
##### Modules load
#module load seqkit/2.11.0
#module load python/3.12.6
module load nanoplot/1.42.0

for i in barcode{01..39}
do
# Quality Control
    NanoPlot --fastq ${WORKPATH}/FASTQ/*${i}.fastq -o ${OUTDIR}/qc_report -t 16
done
```
Run the script
```bash
sbatch nanoplot_script.sh
```

* Retrieve the output files to the device to generate the chart
```bash
rsync -avz --include='barcode*/' --include='barcode*/qc_report/***' --exclude='*' scratch/ky/characterization/results/ /projects/AMRKY/nanoplot_qc/
rsync -avz login@160.120.108.164:/projects/AMRKY/nanoplot_qc ~/internship/nanoplot_qc/
```

* Vizualisation of the nanoplot scatterplot
```bash
#!/usr/bin/env python3

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import os
import re

# 1. Configuration
os.chdir(os.path.expanduser("~/internship/nanoplot_qc"))

# 2. Read the file
df = pd.read_excel("QC_report.xlsx")

# --- IDENTIFICATION BY POSITION (Index) ---

# Col 0 = ID, Col 1 = Barcode, Col 2 = Mean read length, Col 3 = Mean read quality...
# Col -1 (dernière) = Total bases
try:
    c_len = df.columns[2]
    c_qual = df.columns[3]
    c_bases = next(c for c in df.columns if 'TOTAL BASES' in str(c).upper())
    c_bar = df.columns[1]   # 2ème colonne (Barcode)

    print(f"Colonnes identifiées :\n- Longueur : '{c_len}'\n- Qualité : '{c_qual}'\n- Bases : '{c_bases}'")
except Exception as e:
    print(f"Erreur d'identification : {e}")
    print("Colonnes réelles du fichier :", list(df.columns))
    exit()

# 3. Conversion
for col in [c_len, c_qual, c_bases]:

    df[col] = pd.to_numeric(df[col].astype(str).str.replace(',', '').str.strip(), errors='coerce')

# Remove (.0)
df['BC_Label'] = df[c_bar].astype(str).apply(lambda x: re.sub(r'\.0$', '', x))

# Delete lines without data
df = df.dropna(subset=[c_len, c_qual, c_bases])

# 4. scale
x_min, x_max = df[c_len].min() * 0.85, df[c_len].max() * 1.15
y_min, y_max = df[c_qual].min() * 0.85, df[c_qual].max() * 1.15

# 5. chart
sns.set_theme(style="whitegrid")
plt.figure(figsize=(16, 10))

# scatterplot
sns.scatterplot(data=df, x=c_len, y=c_qual,
                size=c_bases, hue=c_qual,
                palette='viridis', sizes=(100, 1000),
                alpha=0.6, edgecolor='black', legend=False)

# Place all barcode numbers
for i in range(len(df)):
    plt.text(df.iloc[i][c_len],
             df.iloc[i][c_qual] + (y_max - y_min)*0.02,
             df.iloc[i]['BC_Label'],
             fontsize=11, fontweight='bold', ha='center')

# limits
plt.xlim(x_min, x_max)
plt.ylim(y_min, y_max)

plt.title("Contrôle Qualité Nanopore : Tous les Barcodes (Vue Globale)", fontsize=18, fontweight='bold', pad=25)
plt.xlabel("Longueur Moyenne des Lectures (bp)", fontsize=14)
plt.ylabel("Qualité Moyenne (Score Q)", fontsize=14)

plt.tight_layout()
plt.savefig("nanoplot_final_complet.png", dpi=300)
print("\nSuccès ! Graphique généré : nanoplot_final_complet.png")
plt.show()
```
Run the script
```bash
python3 viz_final_nanoplot.py
```
### 3. Genome Assembly
#### 3.1. Flye Assembly
De novo assembly using the Flye algorithm, specifically optimized for high-quality Nanopore long-reads to resolve complex genomic repeats
[Access flye_script.sh](/scripts/flye_script.sh)
```bash
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

###########################################
##### Modules load
module load flye/2.9.6

for i in barcode{01..39}
do
     echo "========= Assembly $i ========= \n"
    flye --meta --nano-hq \
        ${FASTQ}/*${i}.fastq \
        -o ${OUTDIR}/${i}/assembly/ -t 16
            
    if [ $? -ne 0 ]; then
        echo "ATTENTION : L'assemblage du barcode$i a échoué, passage au suivant..."
    else            
        echo "Succès pour le $i."
    fi
    
    echo "Analysis $i completed"
done
```

Run the script
```bash
sbatch flye_script.sh
```
* Check the number of contigs in all output files
```bash
for f in barcode*/assembly/*.fasta; do
    echo-n "$f : "
    grep -c "^>" $f
done
```
* Check the barcodes that have a circular genome
```bash
grep -H "Y" /scratch/ky/characterization/results/barcode*/assembly/assembly_info.txt | cut -d'/' -f6,10 | sed 's/assembly_info.txt://' | sort -u
```
#### 3.2. CheckM2 Validation
Quality assessment of the raw assemblies using a machine-learning framework to predict genome completeness and contamination (via the uniref100 database).    
[Access checkm_script.sh](/scripts/checkm_script.sh)
```bash
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
CHECKDB="${WORKPATH}/check_db"
#mkdir -p ${WORKPATH}
#cd ${WORKPATH}

###########################################
##### Modules load
module load checkm2/1.1.0

for i in barcode{01..39}
do
     cp ${OUTDIR}/${i}/assembly/assembly.fasta ${WORKPATH}/check_input/${i}.fasta
     checkm2 database --download --path ${CHECKDB}
     mkdir -p ${OUTDIR}/${i}/assembly/checkm2_results
     CHECKOUT="${OUTDIR}/${i}/assembly/checkm2_results"
     checkm2 predict \
        --threads 16 \
        --input ${WORKPATH}/check_input \
        --output-directory ${CHECKOUT}/ \
        --extension .fasta \
        --database_path ${CHECKDB}/CheckM2_database/uniref100.KO.1.dmnd \
        --force
done
```
Run the script 
```bash
sbatch checkm_script.sh
```

### 4.Assembly Polishing & Quality Assessment
#### 4.1. Medaka Polishing
 Neural network-based polishing to correct consensus sequences and resolve homopolymer errors using the r1041_e82_400bps_sup model.
[Access medaka_script.sh](/scripts/medaka_script.sh)
```bash
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

###########################################
##### Modules load
module load medaka/2.1.1

for i in barcode{01..39}
do
    medaka_consensus -i ${FASTQ}/*${i}.fastq \
         -d ${OUTDIR}/${i}/assembly/assembly.fasta \   
         -m r1041_e82_400bps_sup_v5.2.0 \
         -o ${OUTDIR}/${i}/polishing/ -t 16
done
```
Run  the script
```bash
sbatch medaka_script.sh
```

#### 4.2. BUSCO Evaluation
 Assessment of genome assembly and polishing integrity by searching for Universal Single-Copy Orthologs using the bacteria_odb10 database.
[Access busco_script.sh](/scripts/busco_script.sh)
```bash
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
BUSCO="${WORKPATH}/busco_input"

###########################################
##### Modules load
module load busco/6.0.0

for i in barcode{01..39}
do
 cp ${OUTDIR}/${i}/polishing/consensus.fasta ${WORKPATH}/busco_input/${i}.fasta
    mkdir -p ${OUTDIR}/${i}/polishing/busco_out
    OUT="${OUTDIR}/${i}/polishing/busco_out"
    
    busco -i "$BUSCO" \
        -o "busco_${i}" \
        -m genome \
        -l bacteria_odb10 \
        -c 16 \
        --out_path "$OUT" \
        --force
done
```
Run the script
```bash
sbatch busco_script.sh
```

### 5. Taxonomic Identification
* DIAMOND Assignment
[Access diamond_script.sh](/scripts/diamond_script.sh) 
Ultra-fast protein alignment of genomic contigs against the UniRef90 database to confirm species identity and detect potential inter-species contamination.

```bash
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
#BUSCO="${WORKPATH}/busco_input"
DB_DIAMOND="/projects/AMRKY/uniref90.dmnd"

###########################################
##### Modules load
module load diamond/2.0.9

for i in barcode{01..39}
do
    echo "Analysis  $i"
    singularity exec \
        --bind ${WORKPATH}:${WORKPATH} \
        /usr/local/bioinfo/containers/diamond-2.0.9.sif \
        diamond blastx \
        -d "${DB_DIAMOND}" \
        -q "${OUTDIR}/${i}/polishing/consensus.fasta" \
        -o "${OUTDIR}/${i}/taxonomy_diamond.tsv" \
        --outfmt 6 qseqid sseqid pident length evalue bitscore stitle \
        --threads 16 \
        --max-target-seqs 1 \
        --evalue 1e-5 \
        --id 60

    cp -r ${OUTDIR}/${i}/taxonomy_diamond.tsv /projects/AMRKY/assignation_diamond/${i}.tsv
    echo "Analysis $i completed"
done
```
Run the script 
```bash
sbatch diamond_script.sh
```
* Retrieve the final diamond.tsv on my device
```bash
rsync -avz login@160.120.108.164:/scratch/ky/characterization/results/barcode39/taxonomy_diamond.tsv /projects/AMRKY/assignation_diamond
cd ~/internship
rsync -avz login@160.120.108.164:/projects/AMRKY/assignation_diamond .
```
* Generate the summary table
[Access summary_taxonomy.py](/scripts/summary_taxonomy.py)
```bash
#!/usr/bin/env python3

import pandas as pd
import os
import glob
import re

# 1. Path
base_dir = os.path.expanduser("~/internship/assignation_diamond")
output_file = os.path.expanduser("~/internship/summary_taxonomy_final.csv")

results = []
files = sorted(glob.glob(os.path.join(base_dir, "barcode*.tsv")))

def extract_species(text):
    """Extrait le nom après Tax= et avant TaxID="""
    match = re.search(r"Tax=(.*?) TaxID=", str(text))
    return match.group(1) if match else "Unknown"

for f in files:
    barcode = os.path.basename(f).replace(".tsv", "")
    try:
        # DIAMOND format
        # Col 0: Contig, Col 1: ID, Col 2: Ident, Col 3: Length, Col 4: E-value, Col 5: Bitscore, Col 6: Full Description
        df = pd.read_csv(f, sep='\t', header=None, usecols=[0, 3, 6],
                         names=['contig', 'length', 'description'])

        # Species extraction
        df['species'] = df['description'].apply(extract_species)

        # Grouping by length
        taxon_summary = df.groupby('species')['length'].sum().sort_values(ascending=False)

        if not taxon_summary.empty:
            main_species = taxon_summary.index[0]
            main_length = taxon_summary.iloc[0]
            total_length = taxon_summary.sum()
            purity = (main_length / total_length) * 100

            results.append({
                'Barcode': barcode,
                'Main_Taxon': main_species,
                'Purity_%': round(purity, 2),
                'Total_Assigned_bp': total_length
            })
    except Exception as e:
        print(f"Erreur sur {barcode}: {e}")

# 3. Saving
if results:
    final_df = pd.DataFrame(results)
    final_df.to_csv(output_file, index=False)
    print(f"Summary created : {output_file}")
    print(final_df.head())
else:
    print("None data")
```
Run the script
```bash
python3 summary_taxonomy.py
```

* Go to my device
```bash
cd ~/internship
```
* Generate the taxonomy chart
[Access taxonomy_chart.py](/scripts/taxonomy_chart.py)
```bash
#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os

# 1. Configuration
folder_path = os.path.expanduser("~/internship")
os.chdir(folder_path)
file_name = "summary_taxonomy_final.csv"

# 2. Data loading
df = pd.read_csv(file_name)

# 3. Prepair data for the Pie Chart
seuil = 1
taxo_counts = df['Main_Taxon'].value_counts()
others = taxo_counts[taxo_counts <= seuil].sum()
main_counts = taxo_counts[taxo_counts > seuil]
if others > 0:
    main_counts['Autres (<2 échantillons)'] = others

# 4. Create the chart
plt.figure(figsize=(12, 10))
colors = plt.cm.Paired(range(len(main_counts)))

plt.pie(main_counts,
        labels=main_counts.index,
        autopct='%1.1f%%',
        startangle=140,
        colors=colors,
        pctdistance=0.85,
        explode=[0.05] * len(main_counts))

#  "Donut Chart"
centre_circle = plt.Circle((0,0), 0.70, fc='white')
fig = plt.gcf()
fig.gca().add_artist(centre_circle)

# 5. Title and saving
plt.title("Répartition Taxonomique Globale (N=39 Barcodes)", fontsize=18, fontweight='bold', pad=20)
plt.axis('equal')
plt.tight_layout()

output_img = "repartition_taxonomique_finale.png"
plt.savefig(output_img, dpi=300)
print(f"Graphique circulaire généré : {output_img}")

plt.show()
```
Run the script
```bash
python3 taxonomy_chart.py
```

### 6. Genome Annotation
* Bakta Annotation
 Comprehensive functional annotation of the polished genomes. It identifies CDS, rRNA, tRNA, and provides advanced features like antimicrobial resistance (AMR) gene detection using the Bakta light database.


