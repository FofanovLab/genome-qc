from itertools import filterfalse


def stats_paths(wc):
    outdir = checkpoints.download.get(**wc).output.outdir
    p = os.path.join(outdir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(outdir, "{fasta_path}.fna.gz.csv"),
        fasta_path=globbed.fasta_path
    )
    qc = os.path.join(outdir, "qc")
    expanded = filterfalse(lambda x: x.startswith(qc), expanded)
    return expanded


rule genome_stats:
    """Generate a .csv for every genome containing
    """
    input:
        mean_dist=rules.mean_dist.output.mean_dist,
        fasta=outdir / "{fasta_path}.fna.gz"
    output: os.path.join(outdir, "{fasta_path}.fna.gz.csv")
    script: "../scripts/genome_stats.py"

rule qc:
    """Compile stats files, symlink genomes that pass filtering into passed directory, and
    generate a color-coded tree.
    """
    input:
         summary=root / "summary.tsv",
         stats_paths=stats_paths,
         dmx=rules.dist.output.dmx
    output: outdir / "qc" / "tree.svg"
    script: "../scripts/qc.py"
