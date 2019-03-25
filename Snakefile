import os
from pathlib import Path

configfile: "config.yaml"


outdir = config["outdir"]

include: "rules/mash.smk"
include: "rules/ncbi-genome-download.smk"

rule all:
    # input: "{outdir}/summary.tsv"
    input: lambda x: os.path.join(outdir, "fastas.txt")

