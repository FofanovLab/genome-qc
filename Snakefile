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


rule all:
    input: os.path.join(section_dir, "all.dmx")

checkpoint download:
    threads: 8
    conda: "./envs/ncbi-genome-download.yaml"
    output:
          directory(group_dir),
          metadata=os.path.join(outdir, "summary.tsv"),
    shell:
         "ncbi-genome-download -o '{outdir}' -m '{output.metadata}' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         "--species-taxid {taxid} {group}"

def sketch_paths(wc):
    """Generate the paths to individual sketch files produced by the sketch rule.
    This will propagate the {fasta_path} wildcard from the paste rule to the sketch rule"""
    group_dir = checkpoints.download.get(**wc).output[0]
    p = os.path.join(group_dir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(group_dir, "{fasta_path}.fna.gz.msh"),
        fasta_path=globbed.fasta_path)
    return expanded

rule sketch:
    input: fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
    output: os.path.join(group_dir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    input: sketch_paths
    output: os.path.join(section_dir, "all.msh")
    shell: "mash paste {output} {input}"

rule dist:
    input: os.path.join(section_dir, "all.msh")
    output: os.path.join(section_dir, "all.dmx")
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"
