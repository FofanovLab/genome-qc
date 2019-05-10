import os
from pathlib import Path

configfile: "config.yaml"


species = config["species"]
taxid = config["taxid"]
section = config["section"]
group = config["group"]
threads = config["threads"]

outdir = Path(config["outdir"]) / species
section_dir = outdir / section
group_dir = section_dir / group


rule all:
    input:
        os.path.join(outdir, "qc", "tree.svg"),


include: "rules/genome-download.smk"
include: "rules/mash.smk"
include: "rules/qc.smk"
include: "rules/metadata.smk"
