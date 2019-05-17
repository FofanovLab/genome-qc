from itertools import filterfalse


mash_out = root / "MASH" / f"{genus}_{species}"


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
    input:
        mean_dist=mash_out / "mean_distance.csv",
        fasta=os.path.join(outdir, "{fasta_path}.fna.gz")
    output: os.path.join(outdir, "{fasta_path}.fna.gz.csv")
    script: "../scripts/genome_stats.py"

rule qc:
    input:
         stats_paths=stats_paths,
         dmx=os.path.join(mash_out, "all.dmx")
    output: os.path.join(outdir, "qc", "tree.svg")
    script: "../scripts/qc.py"
