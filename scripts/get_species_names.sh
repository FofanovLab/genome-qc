#!/usr/bin/env bash

# Get values from species_taxid (column 7)
# Skip the first two lines as they contain a comment and column names
cut -f 7 resources/assembly_summary.txt| tail -n +3 |
sort | uniq > resources/taxids.txt

epost -db taxonomy -input resources/taxids.txt |
efetch -format docsum |
xtract -pattern DocumentSummary \
-group DocumentSummary -element ScientificName -element Id |
sort > resources/names_and_taxids.txt
