outdir = config["outdir"]
species = config["species"]

rule download:
    conda:
         "../envs/ncbi-genome-download.yaml"
    output:
          directory("/tmp/GenBankQC")
    shell:
         "ncbi-genome-download -p 4 -o {outdir} --section genbank --assembly-level complete "
         "--genus '{species}' bacteria --assembly-level complete"

# Write path names of FASTAs to temporary file.
rule path_list:
    output:
          temp("{outdir}/.fastas.txt")
    shell:
        "find {outdir} -type f -name 'GCA*fna.gz' > {output}"
