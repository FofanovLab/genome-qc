import re
from pathlib import Path
from common.rename import *


with open("./resources/names_and_taxids.txt") as f:
    pairs = (i.strip().split("\t") for i in f.readlines())
pairs = (i for i in pairs if len(i) == 2)


commands = Path("./commands.sh")
try:
    commands.unlink()
except FileNotFoundError:
    pass

with commands.open("a") as f:
    for p in pairs:
        taxid = p[1]
        name = p[0].replace(" ", "_")
        name = name.replace(" ", "_")
        name = re.sub("[\W]+", "_", name)
        name = rm_duplicates(filter(None, name.split("_")))
        name = "_".join(name)
        f.write(
            "snakemake -j 8 --config "
            f"species='{name}' taxid={taxid} threads=32 -- download\n"
        )
