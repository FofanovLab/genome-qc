import os
from pathlib import Path

configfile: "config.yaml"


species = config["species"]
outdir = os.path.join(config["outdir"], species.replace(' ', '_'))
section = config["section"]
assembly_level = config["assembly_level"]
format = config["format"]
group = config["group"]


include: "rules/ncbi-genome-download.smk"
include: "rules/mash.smk"

rule all:
    input: lambda x: os.path.join(outdir, "dmx.tsv")

