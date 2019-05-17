#!/usr/bin/env bash

epost -db assembly -input $1 -format acc |
elink -target biosample |
efetch -format docsum > $2
