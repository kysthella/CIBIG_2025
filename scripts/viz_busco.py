#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os
import re

# 1. Configuration
folder_path = os.path.expanduser("~/internship/busco")
os.chdir(folder_path)
file_name = "batch_summary.txt"

# 2. Reading
try:
    df = pd.read_csv(file_name, sep=r'\s+', engine='python')
    print(f"Lecture de {file_name} réussie.")
except Exception as e:
    print(f"Erreur : {e}")
    exit()

# --- Names cleaning ---
#  barcode01.fasta -> 01
df['ID'] = df['Input_file'].apply(lambda x: re.sub(r'\D', '', str(x)))

# 3.  (Stacked Bar Chart)
plt.figure(figsize=(12, 12))

# BUSCO standard colours
c_single = '#27ae60'      # green (Complete and unique)
c_duplicated = '#1e8449'  # bold green (Complete and duplicate)
c_fragmented = '#f1c40f'  # Yellow (Fragmented)
c_missing = '#e74c3c'     # Red (Missing)

# From the left to the right
# 1. Complete and  unique
plt.barh(df['ID'], df['Single'], color=c_single, label='Complete & Single (S)')

# 2. Duplicate 
plt.barh(df['ID'], df['Duplicated'], left=df['Single'], color=c_duplicated, label='Complete & Duplicated (D)')

# 3. fragmented
plt.barh(df['ID'], df['Fragmented'], left=df['Single'] + df['Duplicated'], color=c_fragmented, label='Fragmented (F)')

# 4. Missing
plt.barh(df['ID'], df['Missing'], left=df['Single'] + df['Duplicated'] + df['Fragmented'], color=c_missing, label='Missing (M)')

# 4. Styling
plt.title("Évaluation du Polishing Medaka (BUSCO Genes)", fontsize=18, fontweight='bold', pad=25)
plt.xlabel("Pourcentage de gènes (%)", fontsize=14)
plt.ylabel("Barcodes", fontsize=12)
plt.xlim(0, 100)
plt.gca().invert_yaxis() # 01 en haut

# Legend at the end
plt.legend(loc='upper center', bbox_to_anchor=(0.5, -0.05), ncol=4, frameon=False, fontsize=10)

# 5. Saving
plt.tight_layout()
plt.savefig("busco_medaka_presentation.png", dpi=300)
print("Graphique généré : busco_medaka_presentation.png")

plt.show()

