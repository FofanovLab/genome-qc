def sketch_paths(wc):
    group_dir = checkpoints.download.get(**wc).output[0]
    p = os.path.join(group_dir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(group_dir, "{fasta_path}.fna.gz.msh"),
        fasta_path=globbed.fasta_path,
    )
    return expanded

rule sketch:
    input: fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
    output: os.path.join(group_dir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    input: sketch_paths
    output:
        paste=os.path.join(section_dir, "all.msh"),
        sketches=os.path.join(section_dir, "sketches.txt")
    shell:
        "find {section_dir} -type f -name '*fna.gz.msh' > {output.sketches} &&"
        "mash paste {output.paste} -l {output.sketches}"

#TODO Consider avoiding sketch/paste and just giving fastas
# straight to mash dist
rule dist:
    input: os.path.join(section_dir, "all.msh")
    output: os.path.join(section_dir, "all.dmx")
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"

rule mean_dist:
    input: dmx=os.path.join(section_dir, "all.dmx")
    output: mean_dist=os.path.join(section_dir, "mean_distance.csv")
    script: "../scripts/dmx.py"
