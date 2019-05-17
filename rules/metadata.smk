metadata_out = root / "metadata"
ngd_out = root / section / group


rule metadata:
    input: os.path.join(outdir, "runs.csv")
    output: os.path.join(outdir, "metadata.csv")
    script: "../scripts/join_metadata.py"

rule biosample:
    input: os.path.join(metadata_out, "ids.txt")
    output: os.path.join(metadata_out, "biosample.xml")
    shell: "bash scripts/biosample.sh {input} {output}"

rule ids:
    output: os.path.join(metadata_out, "ids.txt")
    shell: "ls {ngd_out} > {output}"

rule xtract_biosample:
    input: os.path.join(metadata_out, "biosample.xml")
    output: os.path.join(metadata_out, "_biosample.tsv")
    shell: "bash scripts/xtract_biosample.sh {input} {output}"

rule parse_biosample:
    input: os.path.join(metadata_out, "_biosample.tsv")
    output:
          os.path.join(metadata_out, "biosample.csv"),
          os.path.join(metadata_out, "sra.csv")
    script: "../scripts/parse_biosample.py"

rule sra:
    input: os.path.join(outdir, "sra.csv")
    output: os.path.join(outdir, "runs.csv")
    shell: "bash scripts/sra.sh {input} {output}"

rule summary:
    output: "resources/assembly_summary.txt"
    shell:
        "wget -P resources "
        "'ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt'"

rule names:
    input: "resources/assembly_summary.txt"
    output: "resources/names_and_taxids.txt"
    shell: "sh scripts/get_species_names.sh && [[ -s {output[0]} ]]"

