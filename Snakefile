from pathlib import Path

configfile: "config.yaml"

species = config["species"]


include: "rules/mash.smk"
# include: "rules/ncbi-genome-download.smk"

rule all:
    input:
         expand(SKETCHES)
        # "genbank/.fastas.txt"

rule download:
    conda:
        "./envs/ncbi-genome-download.yaml"
    output:
        "genbank/summary.tsv"
    threads: int(config["threads"])
    shell:
        "ncbi-genome-download -m {output} -p 4 --section genbank --assembly-level complete "
        "-F fasta --genus '{species}' bacteria --assembly-level complete"

