#!/usr/bin/env bash

# Get values from species_taxid (column 7)
# Skip the first two lines as they contain a comment and column names
rm -f resources/*taxids*
cut -f 7 resources/assembly_summary.txt| tail -n +3 |
sort | uniq | split -d -l 10000 - resources/taxids_

#split -l 10000 resources/taxids.txt resources/taxids_

for f in resources/taxids_*
do
    epost -db taxonomy -input $f |
    efetch -format docsum |
    xtract -pattern DocumentSummary \
    -group DocumentSummary -element ScientificName -element Id |
    sort >> $f.txt &&
    sleep 2
done

cat resources/taxids*.txt >> resources/names_and_taxids.txt
