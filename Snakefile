from pathlib import Path

configfile: "config.yaml"


root = Path(config["root"])
genus = config["genus"]
species = config["species"]
taxid = config["taxid"]
section = config["section"]
group = config["group"]
threads = config["threads"]
assembly_level = config["assembly_level"]
format = config["format"]
outdir = root / "human_readable" / section / group / genus / species
mash_out = outdir / "MASH"
section_dir = outdir / section
group_dir = section_dir / group


rule all:
    input:
        outdir / "qc" / "tree.svg"

rule commands:
    output: "./commands.sh"
    script: "scripts/generate_commands.py"


include: "rules/genome-download.smk"
include: "rules/mash.smk"
include: "rules/qc.smk"
include: "rules/metadata.smk"
