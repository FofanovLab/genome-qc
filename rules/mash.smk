import os

fastas = config["species"] + ".fastas"
species = os.path.join(database, species)

rule sketch:
    conda:
        "../envs/mash.yaml"
    input:
        "{species}/fastas.txt"
    output:
        "{species}/all.msh"
    threads: 8
    shell:
        # "echo {input.fa.split()}"
        "mash sketch -p {threads} -l {input} -o {output}"

rule list:
    input:
        "{species}"
    output:
        "{species}/fastas.txt"
    shell:
        "find {input} -type f -name '*fasta' > {output}"
