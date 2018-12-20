configfile: "config.yaml"

database = config["database"]
species = config["species"]

rule all:
    conda:
        "envs/genbankqc.yaml"
    shell:
        "genbankqc {database} --help"
