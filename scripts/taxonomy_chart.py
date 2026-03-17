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

