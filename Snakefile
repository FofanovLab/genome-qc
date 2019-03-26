import os
from pathlib import Path

configfile: "config.yaml"


species = config["species"]
outdir = os.path.join(config["outdir"], species.replace(' ', '_'))
section = config["section"]
assembly_level = config["assembly_level"]
format = config["format"]
group = config["group"]


include: "rules/mash.smk"
include: "rules/ncbi-genome-download.smk"

rule all:
    # input: "{outdir}/summary.tsv"
    input: lambda x: os.path.join(outdir, "fastas.txt")

