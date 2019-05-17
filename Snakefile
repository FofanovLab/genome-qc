import os
from pathlib import Path

configfile: "config.yaml"


genus = config["genus"]
species = config["species"]
taxid = config["taxid"]
section = config["section"]
group = config["group"]
threads = config["threads"]

root = Path(config["root"])
outdir = root / "human_readable" / section / group / genus / species
section_dir = outdir / section
group_dir = section_dir / group


rule all:
    input:
        os.path.join(outdir, "qc", "tree.svg"),

rule commands:
    output: "scripts/commands.sh"
    script: "scripts/generate_commands.py"


include: "rules/genome-download.smk"
include: "rules/mash.smk"
include: "rules/qc.smk"
include: "rules/metadata.smk"
