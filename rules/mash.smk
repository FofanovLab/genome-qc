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
    """Create one sketch file for every FASTA"""
    input: fasta=os.path.join(outdir, "{fasta_path}.fna.gz")
    output: os.path.join(outdir, "{fasta_path}.fna.gz.msh")
    shell: "mash sketch '{input.fasta}'"

rule paste:
    """Create a master sketch file that contains information for all genomes in the collection.
    This provides a single input file containing the list of sketch files instead of passing all
    of these via stdin which will cause an error if the list is too long.  Since the output of
    this step represents all of the sketch files from the previous step, it also provides a way
    to know if subsequent steps need to be completed.
    """
    #TODO Consider avoiding sketch/paste and just giving FASTAs straight to mash dist
    input: sketch_paths
    output:
        paste=outdir / "all.msh",
        sketches=outdir / "sketches.txt"
    shell:
        "find {outdir} -type f -name '*fna.gz.msh' > {output.sketches} &&"
        "mash paste {output.paste} -l {output.sketches}"

rule dist:
    """Create a distance matrix"""
    input: outdir / "all.msh"
    output: dmx=outdir / "all.dmx"
    threads: threads
    shell: "mash dist -p {threads} -t '{input}' '{input}' > '{output}'"

rule mean_dist:
    """Get the average distance for each genome"""
    input: dmx=rules.dist.output.dmx
    output: mean_dist=outdir / "mean_distance.csv"
    script: "../scripts/dmx.py"
