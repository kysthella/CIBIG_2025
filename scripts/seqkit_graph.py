#!/usr/bin/env python3

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import os

# 1. work directory
os.chdir(os.path.expanduser("~/internship"))

# 2. Data
df = pd.read_csv("summary_seqkit_final.csv")
df['sum_len_mb'] = df['sum_len'] / 1_000_000
df = df.sort_values('sample_id') # On trie avant pour l'affichage

# 3. Figure
sns.set_theme(style="whitegrid")
plt.figure(figsize=(16, 9))

# 4. Barplot 
ax = sns.barplot(data=df, 
                 x="sample_id", 
                 y="sum_len_mb", 
                 hue="sample_id", 
                 legend=False, 
                 palette="viridis")

# 5. Add of the values at the top

for p in ax.patches:
    ax.annotate(format(p.get_height(), '.2f'), # .2f pour 2 décimales
                (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha = 'center', va = 'center', 
                xytext = (0, 9), 
                textcoords = 'offset points',
                fontsize=9, fontweight='bold', rotation=90) # Rotation 90 pour ne pas chevaucher

# 6. Styling
plt.title("Rendement par Barcode (en Mb)", fontsize=18, fontweight='bold', pad=20)
plt.xlabel("Barcodes", fontsize=14)
plt.ylabel("Bases totales (Mb)", fontsize=14)
plt.xticks(rotation=90)

# Augmentation of the top border
plt.ylim(0, df['sum_len_mb'].max() * 1.15)

plt.tight_layout()

# 7. Saving
plt.savefig("seqkit_graph_final.png", dpi=300)
print("Graphique avec valeurs généré : seqkit_graph_final.png")
plt.show()

