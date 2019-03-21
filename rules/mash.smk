from pathlib import Path


fastas = Path("genbank").glob("GCA*fna.gz")
SKETCHES = Path("genbank").glob("GCA*msh")


rule sketch:
    conda:
        "../envs/mash.yaml"
    # use expand(fastas) here
    input:
        "genbank/.fastas.txt"
    output:
        expand(SKETCHES)
    threads: int(config["threads"])
    shell:
        "mash sketch -p {threads} -l {input}"

rule path_list:
    input:
        "genbank/summary.tsv"
    output:
        "genbank/.fastas.txt"
    shell:
       "find genbank -type f -name 'GCA*fna.gz' > {output}"

