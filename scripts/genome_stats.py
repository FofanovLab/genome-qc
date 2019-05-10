import gzip
from pathlib import Path
import re

import attr
import pandas as pd
from logbook import Logger

from Bio import SeqIO


@attr.s
class Genome:
    path = attr.ib(default=Path(), converter=Path)

    def __attrs_post_init__(self):
        self.name = self.path.name
        self.log = Logger(self.name)
        try:
            self.accession_id = self.id_(self.name)
        except AttributeError:
            self.accession_id = "missing"
            self.log.exception("Invalid accession ID")

    @staticmethod
    def id_(name):
        return re.search("GCA_[0-9]*.[0-9]", name).group()

    def get_contigs(self):
        """Get a list of of Seq objects for genome and calculate
            the total the number of contigs.
            """
        try:
            with gzip.open(self.path, "rt") as handle:
                self.contigs = [seq.seq for seq in SeqIO.parse(handle, "fasta")]
            self.count_contigs = len(self.contigs)
        except UnicodeDecodeError:
            self.log.exception()

    def get_assembly_size(self):
        """Calculate the sum of all contig lengths"""
        self.assembly_size = sum((len(str(seq)) for seq in self.contigs))

    def get_unknowns(self):
        """Count the number of unknown bases, i.e. not [ATCG]"""
        # TODO: It might be useful to allow the user to define p.
        p = re.compile("[^ATCG]")
        self.unknowns = sum((len(re.findall(p, str(seq))) for seq in self.contigs))

    def get_distance(self, dmx_mean):
        name = Path(self.path).name
        self.distance = dmx_mean.loc[name][1]

    def get_stats(self, dmx_mean):
        self.get_contigs()
        self.get_assembly_size()
        self.get_unknowns()
        self.get_distance(dmx_mean)
        data = {
            "contigs": self.count_contigs,
            "assembly_size": self.assembly_size,
            "unknowns": self.unknowns,
            "distance": self.distance,
        }
        self.stats = pd.DataFrame(data, index=[self.name])
        self.stats.to_csv(snakemake.input.fasta + ".csv")


genome = Genome(snakemake.input.fasta)
# TODO Reading this csv for every genome can/should be avoided
# Remove the get_distance function
# Only get other stats
# Fill the distance column at the next step
# After reading in stats DataFrame for entire species
dmx_mean = pd.read_csv(snakemake.input.mean_dist, header=None, index_col=0, sep="\t")
genome.get_stats(dmx_mean)
