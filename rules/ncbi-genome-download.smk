import  os
summary ="ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt"


rule get_summary:
    output: "GenBankQC/assembly_summary.txt"
    shell: "wget -P GenBankQC {summary}"

checkpoint species_names:
    conda:
         "../envs/entrez.yaml"
    input: "GenBankQC/assembly_summary.txt"
    output:
          "GenBankQC/species_taxids.txt",
          directory("GenBankQC/names")
    shell:
         "bash scripts/get_species_names.sh"

rule link:
    input: "GenBankQC/Buchnera aphidicola/summary.tsv"
    shell: "find . -name '*fna.gz' | xargs -I % ln -f % ../../"
