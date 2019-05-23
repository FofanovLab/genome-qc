import os
import pandas as pd

outdir = os.path.join(snakemake.config["outdir"], snakemake.config["species"])
summary = pd.read_csv(os.path.join(root, "summary.tsv"), sep="\t", index_col=0)
summary.set_index("biosample", inplace=True)
biosample = pd.read_csv(os.path.join(outdir, "biosample.csv"), index_col=0)
biosample.index.rename("biosample", inplace=True)
runs = pd.read_csv(
    os.path.join(outdir, "runs.csv"),
    index_col=0,
    names=["biosample", "runs"],
    sep="\t",
    error_bad_lines=False,
    warn_bad_lines=False,
)
summary.drop(
    columns=["isolate"], inplace=True
)  # Not needed as it is included in biosample.csv
joined = biosample.join(summary).join(runs)
joined.to_csv(os.path.join(outdir, "metadata.csv"))
