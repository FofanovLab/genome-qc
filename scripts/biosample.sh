#!/usr/bin/env bash

cut -f 1 $1 > GCA_ids.txt

epost -db assembly -input GCA_ids.txt -format acc |
elink -target biosample |
efetch -format docsum > $2
