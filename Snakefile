import os
from pathlib import Path

configfile: "config.yaml"

database = config["database"]
species = config["species"]
FASTAS = [_.stem for _ in Path(database, species).glob("*.fasta")]

include: "rules/mash.smk"
