import os
import re
import functools
from itertools import chain

import attr
import logbook

from pathlib import Path

import pandas as pd

from ete3 import Tree
from genbankqc import config
from common.rename import *
import genbankqc.genome as genome


genus = snakemake.config["genus"]
species = snakemake.config["species"]
taxid = snakemake.config["taxid"]
section = snakemake.config["section"]
group = snakemake.config["group"]
threads = snakemake.config["threads"]

root = Path(snakemake.config["root"])
outdir = root / "human_readable" / section / group / genus / species
section_dir = outdir / section
group_dir = section_dir / group

fastas = outdir.rglob("GCA*fna.gz")
summary = pd.read_csv(root / "summary.tsv", sep="\t", index_col=0)


CRITERIA = ["unknowns", "contigs", "assembly_size", "distance"]

COLORS = {
    "unknowns": "red",
    "contigs": "green",
    "distance": "purple",
    "assembly_size": "orange",
}


@attr.s
class Species(object):
    """Represents a collection of genomes in `path`

    :param path: Path to the directory of related genomes you wish to analyze.
    :param max_unknowns: Number of allowable unknown bases, i.e. not [ATCG]
    :param contigs: Acceptable deviations from median number of contigs
    :param assembly_size: Acceptable deviations from median assembly size
    :param mash: Acceptable deviations from median MASH distances
    :param assembly_summary: a pandas DataFrame with assembly summary information
    """

    path = attr.ib(default=Path(), converter=Path)
    max_unknowns = attr.ib(default=200)
    # TODO These are really about attrib names
    contigs = attr.ib(default=3.0)
    assembly_size = attr.ib(default=3.0)
    mash = attr.ib(default=3.0)
    assembly_summary = attr.ib(default=None)
    metadata = attr.ib(default=None)

    def __attrs_post_init__(self):
        self.log = logbook.Logger(self.path.name)
        self.label = "-".join(
            map(str, [self.max_unknowns, self.contigs, self.assembly_size, self.mash])
        )
        self.paths = config.Paths(
            root=self.path,
            subdirs=[
                "qc",
                ("results", f"qc/{self.label}"),
                ("passed", f"qc/{self.label}/passed"),
                ".logs",
            ],
        )
        self.stats_path = os.path.join(self.paths.qc, "stats.csv")
        self.nw_path = os.path.join(self.paths.qc, "tree.nw")
        self.dmx_path = os.path.join(self.paths.qc, "dmx.csv")
        self.failed_path = os.path.join(self.paths.qc, "failed.csv")
        self.summary_path = os.path.join(self.paths.qc, "qc_summary.txt")
        self.paste_file = os.path.join(self.paths.qc, "all.msh")
        # Figure out if defining these as None is necessary
        self.tree = None
        self.stats = None
        if os.path.isfile(self.stats_path):
            self.stats = pd.read_csv(self.stats_path, index_col=0)
        if os.path.isfile(self.nw_path):
            self.tree = Tree(self.nw_path, 1)
        if os.path.isfile(self.failed_path):
            self.failed_report = pd.read_csv(self.failed_path, index_col=0)
        self.tolerance = {
            "unknowns": self.max_unknowns,
            "contigs": self.contigs,
            "assembly_size": self.assembly_size,
            "distance": self.mash,
        }
        self.passed = self.stats
        self.failed = {}
        self.med_abs_devs = {}
        self.dev_refs = {}
        self.allowed = {"unknowns": self.max_unknowns}

    def __str__(self):
        self.message = [
            "Species: {}".format(self.path.name),
            "Maximum Unknown Bases:  {}".format(self.max_unknowns),
            "Acceptable Deviations:",
            "Contigs, {}".format(self.contigs),
            "Assembly Size, {}".format(self.assembly_size),
            "MASH: {}".format(self.mash),
        ]
        return "\n".join(self.message)

    @property
    def genome_paths(self, ext="fasta"):
        """Returns a generator for every file ending with `ext`

        :param ext: File extension of genomes in species directory
        :returns: Generator of Genome objects for all genomes in species dir
        :rtype: generator
        """
        return [
            os.path.join(self.path, genome)
            for genome in os.listdir(self.path)
            if genome.endswith(ext)
        ]

    @property
    def sketches(self):
        return Path(self.paths.qc).glob("GCA*msh")

    @property
    def total_sketches(self):
        return len(list(self.sketches))

    @property
    def genome_names(self):
        ids = [i.name for i in self.genomes]
        return pd.Index(ids)

    @property
    def biosample_ids(self):
        ids = self.assembly_summary.df.loc[self.accession_ids].biosample.tolist()
        return ids

    # may be redundant. see genome_names attrib
    @property
    def accession_ids(self):
        ids = [i.accession_id for i in self.genomes if i.accession_id is not None]
        return ids

    def get_tree(self):
        from ete3.coretype.tree import TreeError
        import numpy as np
        from skbio.tree import TreeNode
        from scipy.cluster.hierarchy import weighted

        ids = self.dmx.index.tolist()
        triu = np.triu(self.dmx.as_matrix())
        hclust = weighted(triu)
        t = TreeNode.from_linkage_matrix(hclust, ids)
        nw = t.__str__().replace("'", "")
        self.tree = Tree(nw)
        try:
            # midpoint root tree
            self.tree.set_outgroup(self.tree.get_midpoint_outgroup())
        except TreeError:
            self.log.error("Unable to midpoint root tree")
        self.tree.write(outfile=self.nw_path)

    @property
    def stats_files(self):
        return Path(self.paths.qc).glob("GCA*csv")

    def MAD(self, df, col):
        """Get the median absolute deviation for col"""
        MAD = abs(df[col] - df[col].median()).mean()
        return MAD

    def MAD_ref(MAD, tolerance):
        """Get the reference value for median absolute deviation"""
        dev_ref = MAD * tolerance
        return dev_ref

    def bound(df, col, dev_ref):
        lower = df[col].median() - dev_ref
        upper = df[col].median() + dev_ref
        return lower, upper

    def filter_unknown_bases(self):
        """Filter out genomes with too many unknown bases."""
        self.failed["unknowns"] = self.stats.index[
            self.stats["unknowns"] > self.tolerance["unknowns"]
        ]
        self.passed = self.stats.drop(self.failed["unknowns"])

    # TODO Don't use decorator; perform this logic in self.filter
    def check_passed_count(f):
        """
        Count the number of genomes in self.passed.
        Commence with filtering only if self.passed has more than five genomes.
        """

        @functools.wraps(f)
        def wrapper(self, *args):
            if len(self.passed) > 5:
                f(self, *args)
            else:
                self.allowed[args[0]] = ""
                self.failed[args[0]] = ""
                self.log.info("Not filtering based on {}".format(f.__name__))

        return wrapper

    # todo remove unnecessary criteria parameter
    @check_passed_count
    def filter_contigs(self, criteria):
        """
        Only look at genomes with > 10 contigs to avoid throwing off the median absolute deviation.
        Median absolute deviation - Average absolute difference between number of contigs and the
        median for all genomes. Extract genomes with < 10 contigs to add them back in later.
        """
        eligible_contigs = self.passed.contigs[self.passed.contigs > 10]
        not_enough_contigs = self.passed.contigs[self.passed.contigs <= 10]
        # TODO Define separate function for this
        med_abs_dev = abs(eligible_contigs - eligible_contigs.median()).mean()
        self.med_abs_devs["contigs"] = med_abs_dev
        # Define separate function for this
        # The "deviation reference"
        dev_ref = med_abs_dev * self.contigs
        self.dev_refs["contigs"] = dev_ref
        self.allowed["contigs"] = eligible_contigs.median() + dev_ref
        self.failed["contigs"] = eligible_contigs[
            abs(eligible_contigs - eligible_contigs.median()) > dev_ref
        ].index
        eligible_contigs = eligible_contigs[
            abs(eligible_contigs - eligible_contigs.median()) <= dev_ref
        ]
        eligible_contigs = pd.concat([eligible_contigs, not_enough_contigs])
        eligible_contigs = eligible_contigs.index
        self.passed = self.passed.loc[eligible_contigs]

    @check_passed_count
    def filter_MAD_range(self, criteria):
        """
        Filter based on median absolute deviation.
        Passing values fall within a lower and upper bound.
        """
        # Get the median absolute deviation

        med_abs_dev = abs(self.passed[criteria] - self.passed[criteria].median()).mean()
        dev_ref = med_abs_dev * self.tolerance[criteria]
        lower = self.passed[criteria].median() - dev_ref
        upper = self.passed[criteria].median() + dev_ref
        allowed_range = (str(int(x)) for x in [lower, upper])
        allowed_range = "-".join(allowed_range)
        self.allowed[criteria] = allowed_range
        self.failed[criteria] = self.passed[
            abs(self.passed[criteria] - self.passed[criteria].median()) > dev_ref
        ].index
        self.passed = self.passed[
            abs(self.passed[criteria] - self.passed[criteria].median()) <= dev_ref
        ]

    @check_passed_count
    def filter_MAD_upper(self, criteria):
        """
        Filter based on median absolute deviation.
        Passing values fall under the upper bound.
        """
        # Get the median absolute deviation
        med_abs_dev = abs(self.passed[criteria] - self.passed[criteria].median()).mean()
        dev_ref = med_abs_dev * self.tolerance[criteria]
        upper = self.passed[criteria].median() + dev_ref
        self.failed[criteria] = self.passed[self.passed[criteria] > upper].index
        self.passed = self.passed[self.passed[criteria] <= upper]
        upper = "{:.4f}".format(upper)
        self.allowed[criteria] = upper

    def base_node_style(self):
        from ete3 import NodeStyle, AttrFace

        nstyle = NodeStyle()
        nstyle["shape"] = "sphere"
        nstyle["size"] = 2
        nstyle["fgcolor"] = "black"
        for n in self.tree.traverse():
            n.set_style(nstyle)
            if re.match(".*fasta", n.name):
                nf = AttrFace("name", fsize=8)
                nf.margin_right = 150
                nf.margin_left = 3
                n.add_face(nf, column=0)

    # Might be better in a layout function
    def style_and_render_tree(self, file_types=["svg"]):
        from ete3 import TreeStyle, TextFace, CircleFace

        ts = TreeStyle()
        title_face = TextFace(snakemake.config["species"].replace("_", " "), fsize=20)
        title_face.margin_bottom = 10
        ts.title.add_face(title_face, column=0)
        ts.branch_vertical_margin = 10
        ts.show_leaf_name = True
        # Legend
        ts.legend.add_face(TextFace(""), column=1)
        for category in ["Allowed", "Deviations", "Filtered", "Color"]:
            category = TextFace(category, fsize=8, bold=True)
            category.margin_bottom = 2
            category.margin_right = 40
            ts.legend.add_face(category, column=1)
        for i, criteria in enumerate(CRITERIA, 2):
            title = criteria.replace("_", " ").title()
            title = TextFace(title, fsize=8, bold=True)
            title.margin_bottom = 2
            title.margin_right = 40
            cf = CircleFace(4, COLORS[criteria], style="sphere")
            cf.margin_bottom = 5
            filtered_count = len(
                list(filter(None, self.failed_report.criteria == criteria))
            )
            filtered = TextFace(filtered_count, fsize=8)
            filtered.margin_bottom = 5
            allowed = TextFace(self.allowed[criteria], fsize=8)
            allowed.margin_bottom = 5
            allowed.margin_right = 25
            # TODO Prevent tolerance from rendering as a float
            tolerance = TextFace(self.tolerance[criteria], fsize=8)
            tolerance.margin_bottom = 5
            ts.legend.add_face(title, column=i)
            ts.legend.add_face(allowed, column=i)
            ts.legend.add_face(tolerance, column=i)
            ts.legend.add_face(filtered, column=i)
            ts.legend.add_face(cf, column=i)
        for f in file_types:
            out_tree = os.path.join(self.paths.qc, "tree.{}".format(f))
            self.tree.render(out_tree, tree_style=ts)

    def color_tree(self):
        from ete3 import NodeStyle

        self.base_node_style()
        for failed_genome in self.failed_report.index:
            n = self.tree.get_leaves_by_name(failed_genome).pop()
            nstyle = NodeStyle()
            nstyle["fgcolor"] = COLORS[
                self.failed_report.loc[failed_genome, "criteria"]
            ]
            nstyle["size"] = 9
            n.set_style(nstyle)
        self.style_and_render_tree()

    def filter(self):
        self.filter_unknown_bases()
        self.filter_contigs("contigs")
        self.filter_MAD_range("assembly_size")
        self.filter_MAD_upper("distance")
        self.summary()
        self.write_failed_report()

    def write_failed_report(self):

        if os.path.isfile(self.failed_path):
            os.remove(self.failed_path)
        ixs = chain.from_iterable([i for i in self.failed.values()])
        self.failed_report = pd.DataFrame(index=ixs, columns=["criteria"])
        for criteria in self.failed.keys():
            if type(self.failed[criteria]) == pd.Index:
                self.failed_report.loc[self.failed[criteria], "criteria"] = criteria
        self.failed_report.to_csv(self.failed_path)

    def summary(self):
        summary = [
            self.path.name,
            "Unknown Bases",
            f"Allowed: {self.allowed['unknowns']}",
            f"Tolerance: {self.tolerance['unknowns']}",
            f"Filtered: {len(self.failed['unknowns'])}",
            "\n",
            "Contigs",
            f"Allowed: {self.allowed['contigs']}",
            f"Tolerance: {self.tolerance['contigs']}",
            f"Filtered: {len(self.failed['contigs'])}",
            "\n",
            "Assembly Size",
            f"Allowed: {self.allowed['assembly_size']}",
            f"Tolerance: {self.tolerance['assembly_size']}",
            f"Filtered: {len(self.failed['assembly_size'])}",
            "\n",
            "MASH",
            f"Allowed: {self.allowed['distance']}",
            f"Tolerance: {self.tolerance['distance']}",
            f"Filtered: {len(self.failed['distance'])}",
            "\n",
        ]
        summary = "\n".join(summary)
        with open(os.path.join(self.summary_path), "w") as f:
            f.write(summary)
        return summary

    def link_genomes(self):
        for passed_genome in self.passed.index:
            src = root / section / group
            src = next(src.glob(f"*/{passed_genome}")).absolute()
            name = rename_genome(passed_genome, summary)
            dst = (self.paths.qc / name).absolute()
            try:
                dst.symlink_to(src)
            except FileExistsError:
                continue

    def qc(self):
        self.filter()
        self.link_genomes()
        self.get_tree()
        self.color_tree()
        self.log.info("QC finished")

    def select_metadata(self, metadata):
        try:
            self.metadata = metadata.joined.loc[self.biosample_ids]
            self.metadata.to_csv(self.metadata_path)
        except KeyError:
            self.log.exception("Metadata failed")


if len(list(fastas)) >= 10:
    stats = pd.concat(
        [pd.read_csv(f, index_col=0) for f in snakemake.input.stats_paths]
    )
    species = Species(outdir)
    species.stats = stats
    dmx = pd.read_csv(snakemake.input.dmx, index_col=0, sep="\t")
    species.dmx = dmx
    species.qc()
