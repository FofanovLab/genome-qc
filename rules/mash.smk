import os
from pathlib import Path


fastas = [p.as_posix() for p in Path(outdir).rglob("GCA*fna.gz")]


# Write list of FASTAs to disk for use by mash sketch
rule path_list:
    input: "{outdir}/summary.tsv"
    output: "{outdir}/fastas.txt"
    shell:
         "find '{outdir}' -type f -name 'GCA*fna.gz' > '{output}'"

rule sketch:
    conda:
        "../envs/mash.yaml"
    # input: lambda x:  os.path.join(outdir, "fastas.txt")
    input: "{outdir}/fastas.txt"
    output: "{outdir}/all.msh"
    threads: int(config["threads"])
    shell: "mash sketch -p {threads} -l '{input}' -o '{output}'"

rule dist:
    conda:
         "../envs/mash.yaml"
    input: "{outdir}/all.msh"
    output: "{outdir}/dmx.tsv"
    threads: int(config["threads"])
    shell:
         "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"
