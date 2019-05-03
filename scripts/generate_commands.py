from pathlib import Path


with open("./species_and_taxids.txt") as f:
    pairs = (i.strip().split("\t") for i in f.readlines())
pairs = (i for i in pairs if len(i) == 2)


commands = Path("./commands.txt")
try:
    commands.unlink()
except FileNotFoundError:
    pass

with commands.open("a") as f:
    for p in pairs:
        species = p[0].replace(" ", "_")
        taxid = p[1]
        f.write(
            "srun -o %J.out snakemake -q -j 999 --use-conda --config "
             f"species='{species}' taxid={taxid} threads=32\n"
        )
