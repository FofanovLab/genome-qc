#!/usr/bin/env bash

epost -db sra -input $1 -format acc | \
        efetch -format docsum | \
        xtract -pattern DocumentSummary/* \
               -group Biosample -ret '\t' -element Biosample \
               -group Runs -sep ',' -element Runs/Run@acc \
               >> $2
