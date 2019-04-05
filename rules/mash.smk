import os


def get_paths():
    globbed = glob_wildcards(os.path.join(section_dir, "{id_path}.fna.gz"))
    return globbed


# Make sure this is run only for new genomes
rule sketch:
    input:
           "GenBankQC/Buchnera aphidicola/summary.tsv",
           fasta=os.path.join(section_dir, "{id_path}.fna.gz")
    output: os.path.join(section_dir, "{id_path}.fna.gz.msh")
    shell: "mash sketch -o '{section_dir}/MASH/' '{input.fasta}'"

rule paste:
    input:
            expand(os.path.join(section_dir, "{id_path}.fna.gz.msh"),
                  id_path=get_paths().id_path)
    # output: "{section_dir}/all.msh"
    # shell: "mash paste all {input}"

# Use mash paste to avoid needing to re-sketch fastas
# rule dist:
#     conda: "../envs/mash.yaml"
#     input: "GenBankQC/Buchnera aphidicola/all.msh"
#     output: "GenBankQC/Buchnera aphidicola/dmx.tsv"
#     threads: threads
#     shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"
