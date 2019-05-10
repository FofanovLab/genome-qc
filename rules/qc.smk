def stats_paths(wc):
    group_dir = checkpoints.download.get(**wc).output[0]
    p = os.path.join(group_dir, "{fasta_path}.fna.gz")
    globbed = glob_wildcards(p)
    expanded = expand(
        os.path.join(group_dir, "{fasta_path}.fna.gz.csv"),
        fasta_path=globbed.fasta_path)
    return expanded


rule genome_stats:
    input: mean_dist=os.path.join(section_dir, "mean_distance.csv"),
         fasta=os.path.join(group_dir, "{fasta_path}.fna.gz")
    output: os.path.join(group_dir, "{fasta_path}.fna.gz.csv")
    script: "../scripts/genome_stats.py"

rule qc:
    input:
         stats_paths=stats_paths,
         dmx=os.path.join(section_dir, "all.dmx")
    output: os.path.join(outdir, "qc", "tree.svg")
    script: "../scripts/qc.py"
