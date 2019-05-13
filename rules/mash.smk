out = root / "MASH" / f"{genus}_{species}"


def sketch_paths(wc):
    outdir = checkpoints.download.get(**wc).output.outdir
    p = os.path.join(outdir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(outdir, "{fasta_path}.fna.gz.msh"),
        fasta_path=globbed.fasta_path,
    )
    return expanded

rule sketch:
    input: fasta=os.path.join(outdir, "{fasta_path}.fna.gz")
    output: os.path.join(outdir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    input: sketch_paths
    output:
        paste=os.path.join(out, "all.msh"),
        sketches=os.path.join(out, "sketches.txt")
    shell:
        "find {outdir} -type f -name '*fna.gz.msh' > {output.sketches} &&"
        "mash paste {output.paste} -l {output.sketches}"

#TODO Consider avoiding sketch/paste and just giving fastas
# straight to mash dist
rule dist:
    input: os.path.join(out, "all.msh")
    output: os.path.join(out, "all.dmx")
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"

rule mean_dist:
    input: dmx=os.path.join(out, "all.dmx")
    output: mean_dist=os.path.join(out, "mean_distance.csv")
    script: "../scripts/dmx.py"
