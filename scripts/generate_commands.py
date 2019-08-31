from pathlib import Path

root = Path(snakemake.config["root"])
section = snakemake.config["section"]
group = snakemake.config["group"]
outdir = root / "human_readable" / section / group
pairs = outdir.glob("*/*")

commands = Path("./commands.sh")
try:
    commands.unlink()
except FileNotFoundError:
    pass


with commands.open("a") as f:
    for p in pairs:
        genus, species = p.parts[-2:]
        f.write(
            f"snakemake -j 999 --config genus='{genus}' "
            f"species='{species}' threads=32\n"
        )

