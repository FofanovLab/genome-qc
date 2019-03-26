from pathlib import Path


rule download:
    output: "{outdir}/summary.tsv",
    conda:
         "../envs/ncbi-genome-download.yaml"
    threads: int(config["threads"])
    shell:
         "ncbi-genome-download -o '{outdir}' -m '{outdir}/summary.tsv' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         " --genus '{species}' {group}"
