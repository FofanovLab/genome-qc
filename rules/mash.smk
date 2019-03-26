from pathlib import Path


fastas = Path("genbank").glob("GCA*fna.gz")
SKETCHES = Path("genbank").glob("GCA*msh")
sketch_out = os.path.join(outdir, 'all')


rule sketch:
    conda:
        "../envs/mash.yaml"
    input: lambda x:  os.path.join(outdir, "fastas.txt")
    # output: expand(SKETCHES)
    threads: int(config["threads"])
    shell: "mash sketch -p {threads} -l '{input}' -o '{sketch_out}'"
