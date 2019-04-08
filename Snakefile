from pathlib import Path

configfile: "config.yaml"


species = config["species"]
taxid = config["taxid"]
outdir = Path(config["outdir"]) / species
section = config["section"]
group = config["group"]
section_dir = os.path.join(outdir, section)
group_dir = os.path.join(outdir, section, group)
assembly_level = config["assembly_level"]
format = config["format"]
threads = config["threads"]


# include: "rules/ncbi-genome-download.smk"
include: "rules/mash.smk"

rule all:
    input: os.path.join(section_dir, "all.dmx")
