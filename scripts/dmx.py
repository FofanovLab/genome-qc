import pandas as pd
from pathlib import Path


dmx = pd.read_csv(snakemake.input.dmx, index_col=0, sep="\t")
import pdb;pdb.set_trace()
names = [Path(i).name for i in dmx.index]
dmx.index = names
dmx.columns = names
dmx.to_csv(snakemake.input.dmx, sep="\t")
dmx.mean().to_csv(snakemake.output.mean_dist, sep="\t")
