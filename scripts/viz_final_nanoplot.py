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

