#!/usr/bin/env bash

cut -f 1 $1 > GCA_ids.txt

epost -db assembly -input GCA_ids.txt -format acc |
elink -target biosample |
efetch -format docsum > $2

#xtract -input e_coli.xml -pattern DocumentSummarySet/* \
#       -group Id \
#       -if Id@db -equals "BioSample" -or Id@db -equals "SRA"\
#       -element Id  | head

