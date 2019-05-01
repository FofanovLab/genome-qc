#!/usr/bin/env bash

# Get values from species_taxid (column 7)
# Skip the first two lines as they contain a comment and column names
cut -f 7 ~/.cache/ncbi-genome-download/genbank_bacteria_assembly_summary.txt| tail -n +3 |
sort | uniq > GenBankQC/species_taxids.txt

mkdir GenBankQC/names
epost -db taxonomy -input GenBankQC/species_taxids.txt | \
    efetch -format docsum | \
        xtract -pattern DocumentSummary \
         -group DocumentSummary -element ScientificName -element Id \
          | sort > GenBankQC/species_and_taxids.txt
