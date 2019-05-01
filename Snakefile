import os
from pathlib import Path

configfile: "config.yaml"


species = config["species"]
taxid = config["taxid"]
outdir = Path(config["outdir"]) / species
section = config["section"]
group = config["group"]
section_dir = os.path.join(outdir, section)
group_dir = os.path.join(outdir, section, group)
threads = config["threads"]


def stats_paths(wc):
    group_dir = checkpoints.download.get(**wc).output[0]
    p = os.path.join(group_dir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(group_dir, "{fasta_path}.fna.gz.csv"),
        fasta_path=globbed.fasta_path)
    return expanded


rule all:
    input: os.path.join(outdir, "qc", "tree.svg")


include: "rules/genome-download.smk"
include: "rules/mash.smk"
include: "rules/qc.smk"
include: "rules/metadata.smk"
