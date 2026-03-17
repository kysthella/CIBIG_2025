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

