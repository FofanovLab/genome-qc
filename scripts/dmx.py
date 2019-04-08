import pandas as pd
from pathlib import Path


dmx = pd.read_csv(snakemake.input.dmx, index_col=0, sep="\t")
names = [Path(i).name for i in dmx.index]
dmx.index = names
dmx.columns = names
mean = dmx.mean()
mean.to_csv(snakemake.output.mean_dist, sep="\t")
