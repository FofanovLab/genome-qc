import pandas as pd
import xml.etree.cElementTree as ET

ATTRIBUTES = [
    "BioSample",
    "SRA",
    "geo_loc_name",
    "collection_date",
    "strain",
    "isolation_source",
    "host",
    "collected_by",
    "sample_type",
    "sample_name",
    "host_disease",
    "host_health_state",
    "serovar",
    "env_biome",
    "env_feature",
    "ref_biomaterial",
    "env_material",
    "isol_growth_condt",
    "num_replicons",
    "sub_species",
    "host_age",
    "genotype",
    "host_sex",
    "serotype",
    "host_disease_outcome",
    ]

db_xp = '[@db="{}"]'
xp_tups = []
for attrib in ATTRIBUTES:
    xp_tups.append((attrib,
                    "harmonized_name",
                    '[@harmonized_name="{}"]',
                    )
                   )


def parse_sample_data(sample_data):
    data = {}
    ids = sample_data.findall("Ids/Id")
    attributes = sample_data.findall("Attributes/Attribute")
    for elem in ids:
        for attrib, key, xp in [("BioSample", "db", db_xp), ("SRA", "db", db_xp)]:
            e = elem.find(xp.format(attrib))
            if e is not None:
                name = e.get(key)
                attribute = e.text
                data[name] = attribute
    for elem in attributes:
        for attrib, key, xp in xp_tups:
            e = elem.find(xp.format(attrib))
            if e is not None:
                name = e.get(key)
                attribute = e.text
                data[name] = attribute
    return data


xml = snakemake.input[0]
frames = []
with open(xml) as f:
    # TODO Use takewhile here to chunk file based on valid xml
    root = ET.parse(xml)
    for tree in root.findall("DocumentSummary"):
        sample_data = tree.find("SampleData/BioSample")
        data = parse_sample_data(sample_data)
        frames.append(data)

df = pd.concat([pd.DataFrame(frame, index=[frame["BioSample"]]) for frame in frames])
df.set_index("BioSample", inplace=True)
df.to_csv(snakemake.output[0])
sra = df.SRA[df.SRA.notnull()]
sra.to_csv(snakemake.output[1], index=False)
