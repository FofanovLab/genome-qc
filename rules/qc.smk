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

rule rename:
    # input: directory(os.path.join(group_dir, "qc"))
    script: "../scripts/rename.py"

