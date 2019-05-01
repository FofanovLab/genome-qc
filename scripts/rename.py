import re
from pathlib import Path

import pandas as pd

species = snakemake.config["species"]
outdir = Path(snakemake.config["outdir"]) / species
section = snakemake.config["section"]
group = snakemake.config["group"]
group_dir = outdir / section / group


def parse_genome_id(genome):
    genome_id = re.search("GCA_[0-9]*.[0-9]", genome).group()
    return genome_id


def rm_duplicates(seq):
    """Remove duplicate strings during renaming
    """
    seen = set()
    seen_add = seen.add
    return [x for x in seq if not (x in seen or seen_add(x))]


def clean_up_name(name):
    rm_words = re.compile(
        r'((?<=_)(sp|sub|substr|subsp|str|strain)(?=_))'
    )
    name = re.sub(' +', '_', name)
    name = rm_words.sub('_', name)
    name = re.sub('_+', '_', name)
    name = re.sub('[\W]+', '_', name)
    name = rm_duplicates(name.split('_'))
    name = '_'.join(name)
    return name


def rename_genome(genome, assembly_summary):
    """Rename FASTAs based on info in the assembly summary
    """

    genome_id = parse_genome_id(genome)
    infraspecific_name = assembly_summary.at[genome_id, 'infraspecific_name']
    organism_name = assembly_summary.at[genome_id, 'organism_name']
    if type(infraspecific_name) == float:
        infraspecific_name = ''
    isolate = assembly_summary.at[genome_id, 'isolate']
    if type(isolate) == float:
        isolate = ''
    assembly_level = assembly_summary.at[genome_id, 'assembly_level']
    name = "_".join([
        genome_id,
        organism_name,
        species,
        infraspecific_name,
        isolate,
        assembly_level])
    name = clean_up_name(name) + ".fna.gz"
    return name


summary = pd.read_csv(outdir / 'summary.tsv', sep="\t", index_col=0)
genomes = (Path(outdir) / "qc").glob("*fna.gz")
for genome in genomes:
    renamed = rename_genome(genome.as_posix(), summary)
    renamed = (genome.parent / renamed).absolute()
    genome.absolute().rename(renamed)

