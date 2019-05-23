from itertools import filterfalse


def sketch_paths(wc):
    outdir = checkpoints.download.get(**wc).output.outdir
    p = os.path.join(outdir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(outdir, "{fasta_path}.fna.gz.msh"),
        fasta_path=globbed.fasta_path,
    )
    qc = os.path.join(outdir, "qc")
    expanded = filterfalse(lambda x: x.startswith(qc), expanded)
    return expanded

rule sketch:
    input: fasta=os.path.join(outdir, "{fasta_path}.fna.gz")
    output: os.path.join(outdir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    input: sketch_paths
    output:
        paste=outdir / "all.msh",
        sketches=outdir / "sketches.txt"
    shell:
        "find {outdir} -type f -name '*fna.gz.msh' > {output.sketches} &&"
        "mash paste {output.paste} -l {output.sketches}"

#TODO Consider avoiding sketch/paste and just giving fastas
# straight to mash dist
rule dist:
    input: outdir / "all.msh"
    output: dmx=outdir / "all.dmx"
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"

rule mean_dist:
    input: dmx=rules.dist.output.dmx
    output: mean_dist=outdir / "mean_distance.csv"
    script: "../scripts/dmx.py"
