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
assembly_level = config["assembly_level"]
format = config["format"]
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

checkpoint download:
    threads: 8
    conda: "./envs/ncbi-genome-download.yaml"
    output:
          directory(group_dir),
          metadata=os.path.join(outdir, "summary.tsv")
    # TODO Extract to shell script
    shell:
         "ncbi-genome-download -o '{outdir}' -m '{output.metadata}' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         "--species-taxid {taxid} {group}"

def sketch_paths(wc):
    """Generate the paths to individual sketch files produced by the sketch rule.
    This will propagate the {fasta_path} wildcard from the paste rule to the sketch
    rule"""
    group_dir = checkpoints.download.get(**wc).output[0]
    p = os.path.join(group_dir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(group_dir, "{fasta_path}.fna.gz.msh"),
        fasta_path=globbed.fasta_path,
    )
    return expanded

rule sketch:
    input: fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
    output: os.path.join(group_dir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    input: sketch_paths
    output:
        paste=os.path.join(section_dir, "all.msh"),
        sketches=os.path.join(section_dir, "sketches.txt")
    shell:
        "find {section_dir} -type f -name '*fna.gz.msh' > {output.sketches} &&"
        "mash paste {output.paste} -l {output.sketches}"

rule dist:
    input: os.path.join(section_dir, "all.msh")
    output: os.path.join(section_dir, "all.dmx")
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"

rule mean_dist:
    input: dmx=os.path.join(section_dir, "all.dmx")
    output: mean_dist=os.path.join(section_dir, "mean_distance.csv")
    script: "scripts/dmx.py"

rule genome_stats:
    input: mean_dist=os.path.join(section_dir, "mean_distance.csv"),
           fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
    output: os.path.join(group_dir, "{fasta_path}.fna.gz.csv")
    script: "scripts/genome_stats.py"

rule qc:
    input:
        stats_paths=stats_paths,
        dmx=os.path.join(section_dir, "all.dmx")
    # TODO Move qc and results elsewhere
    #  This messes up globbing the fastas because glob finds fastas in qc dir
    output: os.path.join(outdir, "qc", "tree.svg")
    script: "scripts/qc.py"

rule rename:
    # input: directory(os.path.join(group_dir, "qc"))
    script: "scripts/rename.py"

rule join_metadata:
    input: os.path.join(outdir, "runs.csv")
    output: os.path.join(outdir, "metadata.csv")
    script: "scripts/join_metadata.py"

rule biosample:
    input: os.path.join(outdir, "summary.tsv")
    output: os.path.join(outdir, "biosample.xml")
    shell: "bash scripts/biosample.sh {input} {output}"

rule parse_biosample:
    input: os.path.join(outdir, "biosample.xml")
    output:
        os.path.join(outdir, "biosample.csv"),
        os.path.join(outdir, "sra.csv")
    script: "scripts/parse_biosample.py"

rule sra:
    input: os.path.join(outdir, "sra.csv")
    output: os.path.join(outdir, "runs.csv")
    shell: "bash scripts/sra.sh {input} {output}"

