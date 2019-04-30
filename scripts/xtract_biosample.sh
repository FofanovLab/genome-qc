#!/usr/bin/env bash

xtract -input $1 -pattern DocumentSummarySet/* \
       -group Id \
       -if Id@db -equals "BioSample" -or Id@db -equals "SRA"\
       -element Id@db -element Id \
       -group Attribute \
       -if Attribute@harmonized_name \
       -element Attribute@harmonized_name -element Attribute \
       > $2


