from pathlib import Path



rule download:
    output: "{outdir}/summary.tsv"
    threads: int(config["threads"])
    conda:
         "../envs/ncbi-genome-download.yaml"
    shell:
         "ncbi-genome-download -H -o {outdir} -m '{outdir}/summary.tsv' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         " --genus '{species}' {group}"

# Write path names of FASTAs to temporary file.
rule path_list:
    input: "{outdir}/summary.tsv"
    output: "{outdir}/fastas.txt"
    shell:
        "find {outdir}/genbank -type f -name 'GCA*fna.gz' > {output}"
