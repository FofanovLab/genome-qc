
from pathlib import Path

root = Path(f"{snakemake.config['outdir']}")
names = root / "names"
names.mkdir(exist_ok=True)


def parse_names():
    with open(root / "scientific_names.tsv") as f:
        for l in f:
            split = l.split('\t')
            id, name = split[0], split[1].strip()
            with open(names / f"{id}.txt", "w") as outfile:
                outfile.write(l)

parse_names()
