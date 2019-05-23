checkpoint download:
    threads: 16
    output:
          outdir=directory(outdir)
    shell:
         "ncbi-genome-download -H -o {root} "
         "-p {threads} --section {section} -F {format} "
         "--assembly-level '{assembly_level}' "
         "--species-taxid {taxid} {group}"
