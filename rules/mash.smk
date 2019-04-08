import os

from snakemake.io import expand, glob_wildcards
#
# def ids_and_names():
#
#     """Make the accession ID and FASTA name accessible via a Wildcards object"""
#     p = os.path.join(group_dir, "{id}", "{name}.fna.gz")
#     return glob_wildcards(p)
#
#
# def fasta_paths():
#     """Make the path to FASTAs name accessible via a Wildcards object"""
#     p = os.path.join(group_dir, "{fasta_path}.fna.gz")
#     return glob_wildcards(p)
#
#
# def fasta_paths(wc):
#     """Make the path to FASTAs name accessible via a Wildcards object"""
#     group_dir = checkpoints.download.get(**wc).output[0]
#     p = os.path.join(group_dir, "{fasta_path}.fna.gz")
#     globbed = glob_wildcards(p)
#     expanded = expand(
#         os.path.join(group_dir, "{fasta_path}.fna.gz"),
#         fasta_path=globbed.fasta_path )
#     return expanded

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

checkpoint download:
    threads: 8
    conda: "../envs/ncbi-genome-download.yaml"
    # this may need to be a dir
    output:
          directory(group_dir),
          metadata=os.path.join(outdir, "summary.tsv"),
    shell:
         "ncbi-genome-download -o '{outdir}' -m '{output.metadata}' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         "--species-taxid {taxid} {group}"

rule sketch:
    input:
         os.path.join(outdir, "summary.tsv"),
         fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
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
