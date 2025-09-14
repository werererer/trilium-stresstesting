#!/usr/bin/env python3
# wordnet-ask.py
# pip install nltk tqdm

import csv
from pathlib import Path
from nltk.corpus import wordnet as wn
import nltk
from tqdm import tqdm

# Ensure WordNet is downloaded
try:
    wn.synsets("dog")
except LookupError:
    nltk.download("wordnet")
    nltk.download("omw-1.4")  # optional multilingual data

# Prepare rows for CSV
rows = []

# Iterate over all synsets directly
for syn in tqdm(list(wn.all_synsets()), desc="🔍 Processing synsets"):
    synset_id = syn.name()  # e.g., "dog.n.01"
    definition = syn.definition()
    synonyms = ";".join(syn.lemma_names())  # join lemma names

    for lemma in syn.lemma_names():
        rows.append([lemma, synset_id, definition, synonyms, ""])  # empty "imported"

# Write to CSV
csv_path = Path("syn-entries.csv")
with open(csv_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["word", "synset", "definition", "synonyms", "imported"])
    writer.writerows(rows)

print(f"\n✅ Wrote {len(rows)} entries (word-synset-synonym sets) to {csv_path}")

