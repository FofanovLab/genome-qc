=============================================
           GenBank Quality Control
=============================================

GenBankQC is an effort to address the quality control problem for public
databases such as the National Center for Biotechnology Information's `GenBank`_.
The goal is to offer a simple, efficient, and automated solution for
**downloading and assessing the quality of your genomes**.

GenBankQC leverages several open-source tools and is built on `Snakemake`_.

Features
--------

- Labelling/annotation-independent quality control based on:

  - Genome distance estimation using `MASH`_
  - Number of unknown bases
  - Number of contigs
  - Assembly size

- Flagging potential outliers to exclude them from polluting your pipelines

The current implementation provides a curated subset of genomes that pass filtering based
on the above metrics.  This subset is provided as a directory of symlinked FASTA
files that can be used as input to subsequent pipelines.

The GenBankQC work-flow consists of the following steps:

#. Download genomes for a given species or list of species.
    * This functionality is provided by `ncbi-genome-download`_.

#. Generate `MASH`_ sketch files and statistics for each genome

#. Generate a distance matrix using the `MASH`_ sketch files

#. Flag potential outliers:
    * Genomes with more than than a certain number of unknown bases (200 by default)
    * Genomes with an average `MASH`_ distance greater than the upper end of the median absolute deviation.
    * Median absolute deviation is used to filter based on the number of contigs and assembly size.

#. Visualize the results with a color coded tree using the `ETE Toolkit`_

Installation
------------

Conda is the most important depedency as it will handle installing all other dependencies.
If you don't yet have a functional conda environment, please download and install `Miniconda`_.
After downloading and installing miniconda:

.. code::

    conda create -n genbankqc -c etetoolkit -c biocore pip snakemake ete3 scikit-bio
    source activate genbankqc
    pip install genbankqc

Usage
-----

You can now test the pipeline which is configured to run on Buchnera aphidicola default,
just as an example:

.. code::

    snakemake -j 8

The ``-j 8`` option tells snakemake to try and use 8 cores, which results in certain parts of the
pipeline being run in parallel, including downloading genomes.

The usage and the internals of the pipeline are easily discoverable because Snakemake facilitates
defining pipelines in a self-documenting fashion.  Running ``snakemake -np`` in this repository without
changing ``config.yaml`` will do a dry run and print the commands that will be used.

.. code::

    $ snakemake -np
    Building DAG of jobs...
    Job counts:
            count   jobs
            1       all
            1       dist
            1       download
            1       paste
            1       qc
            5

    checkpoint download:
        output: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola
        jobid: 3
    Downstream jobs will be updated after completion.

    ncbi-genome-download -H -o genomes -p 1 --section genbank -F fasta --assembly-level 'complete,contig,chromosome,scaffold' --species-taxid 9 bacteria


The first job will download genomes from NCBI.  Snakemake doesn't have enough information to generate
jobs for the whole pipeline until the genomes are downloaded and it can see what files it is working with.


.. :: code

    rule paste:
        input: <unknown>
        output: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.msh, genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/sketches.txt
        jobid: 5

    find genomes/human_readable/genbank/bacteria/Buchnera/aphidicola -type f -name '*fna.gz.msh' > genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/sketches.txt &&mash paste genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.msh -l genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/sketches.txt

    rule dist:
        input: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.msh
        output: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.dmx

    mash dist -p 1 -t 'genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.msh' 'genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.msh' > 'genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.dmx'

    rule qc:
        input: genomes/summary.tsv, <unknown>, genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/all.dmx
        output: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/qc/tree.svg
        jobid: 1

    localrule all:
        input: genomes/human_readable/genbank/bacteria/Buchnera/aphidicola/qc/tree.svg
        jobid: 0

Please see the ``.smk`` files in the ``rules`` directory for more information on each step.  There
you can see which commands are being run and the relevant source code.

For cases in which you would like to download genomes for many species, e.g. all bacteria genomes,
special care is required to avoid unreasonable run times.  The suggested workaround is to run
``ncbi-genome-download`` before running Snakemake.  This avoids the problem of running many thousands of
``ncbi-genome-download`` commands.  To download all bacteria genomes:

.. code::

    ncbi-genome-download -H -o genomes -p 16 --section genbank -F fasta --assembly-level 'complete,contig,chromosome,scaffold' bacteria


Then the quality control steps of this pipeline can be run for each species.  Included in this
repository is a script for generating the commands needed to run this workflow on all bacteria.  The
script assumes that genomes were downloaded by ``ncbi-genome-download`` using the ``--human-readable``
flag.  It will determine what commands are need by the directory structure output by
``ncbi-genome-download``.  To generate these commands, run:

.. code::

    python scripts/generate_commands.py

This will create a new file, ``scripts/commands.sh``, with the commands needed to complete
the pipeline.


.. _NCBITK:  https://github.com/andrewsanchez/NCBITK
.. _GenBank: https://www.ncbi.nlm.nih.gov/genbank/
.. _ETE Toolkit: http://etetoolkit.org/
.. _Miniconda: https://conda.io/miniconda.html
.. _MASH: http://mash.readthedocs.io/en/latest/
.. _ncbi-genome-download: https://github.com/kblin/ncbi-genome-download
.. _genbankqc.readthedocs.io: http://genbankqc.readthedocs.io/en/latest/
.. _Snakemake: https://snakemake.readthedocs.io/en/stable/

.. image:: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square
           :target: https://yangsu.github.io/pull-request-tutorial/
