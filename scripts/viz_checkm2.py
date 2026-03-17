#!/usr/bin/env python3

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import os
import re

# 1. Configuration
folder_path = os.path.expanduser("~/internship/checkm2_results")
os.chdir(folder_path)
file_name = "quality_report.tsv"

# 2. Lecture et nettoyage
df = pd.read_csv(file_name, sep='\t')
df['ShortName'] = df['Name'].apply(lambda x: re.sub(r'\D', '', str(x)))

# 3. Création du graphique
sns.set_theme(style="whitegrid")
fig, ax = plt.subplots(figsize=(14, 10))

# POINTS EN COULEURS TRÈS CLAIRES (Pastel1)
# s=150 pour des bulles assez larges, alpha=0.4 pour la clarté
scatter = sns.scatterplot(data=df, x='Completeness', y='Contamination', 
                          hue='Completeness', palette='Pastel1', 
                          s=180, alpha=0.4, edgecolor='gray', linewidth=0.5, legend=False)

# 4. NUMÉROS AU CENTRE (Noir intense pour trancher avec le pastel)
for i in range(len(df)):
    ax.text(df.Completeness[i], df.Contamination[i], 
            df.ShortName[i], fontsize=9, fontweight='bold', 
            ha='center', va='center', color='black')

# 5. LIGNES DE SEUIL (Discrètes)
plt.axvline(90, color='green', linestyle='--', alpha=0.3)
plt.axhline(5, color='red', linestyle='--', alpha=0.3)

# 6. Habillage
plt.title("Validation CheckM2 : Complétude vs Contamination (Vue Claire)", fontsize=18, fontweight='bold', pad=20)
plt.xlabel("Complétude (%)", fontsize=14)
plt.ylabel("Contamination (%)", fontsize=14)

# Ajuster les limites pour ne pas coller aux bords
plt.xlim(df.Completeness.min()-2, 102)
plt.ylim(-0.5, df.Contamination.max()+2)

plt.tight_layout()
plt.savefig("checkm2_pastel_centre.png", dpi=300)

# 7. GÉNÉRATION DE LA LISTE DES ÉCHECS
low_quality_df = df[(df['Completeness'] < 90) | (df['Contamination'] > 5)]
with open("barcodes_a_rejeter.txt", "w") as f:
    f.write("LISTE DES BARCODES HORS CRITÈRES (>5% Contamination ou <90% Complétude)\n")
    f.write("-" * 75 + "\n")
    if not low_quality_df.empty:
        f.write(low_quality_df[['Name', 'Completeness', 'Contamination']].to_string(index=False))
    else:
        f.write("Tous les échantillons respectent les seuils de qualité.")

print("Graphique pastel généré : checkm2_pastel_centre.png")
plt.show()

