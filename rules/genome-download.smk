assembly_level = config["assembly_level"]
format = config["format"]

checkpoint download:
    threads: 16
    conda: "../envs/ncbi-genome-download.yaml"
    output:
          directory(group_dir),
          metadata=os.path.join(outdir, "summary.tsv")
    shell:
         "ncbi-genome-download -o '{outdir}' -m '{output.metadata}' "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level {assembly_level} "
         "--species-taxid {taxid} {group}"

