from pathlib import Path
import yaml


# ==============================================================================
# CONFIGURATION
# ==============================================================================

BASE_DIR = Path(__file__).resolve().parents[1]

METADATA_DIR = BASE_DIR / "metadata" / "tpch_sf1"
MODELS_DIR = BASE_DIR / "models"

STAGING_DIR = MODELS_DIR / "01_stg" / "tpch_sf1"
RDV_DIR = MODELS_DIR / "02_rdv" / "tpch_sf1"

HUBS_DIR = RDV_DIR / "hubs"
LINKS_DIR = RDV_DIR / "links"
SATS_DIR = RDV_DIR / "satellites"

SOURCES_FILE = MODELS_DIR / "00_raw" / "sources.yml"


# ==============================================================================
# HELPERS
# ==============================================================================

def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)

    if not data:
        raise ValueError(f"Empty YAML file: {path}")

    return data


def parse_source_model(source_model: str) -> tuple[str, str, str]:
    """
    Convert:

        PRO_RAW.TPCH_SF1.CUSTOMER

    into:

        database = PRO_RAW
        schema   = TPCH_SF1
        table    = CUSTOMER
    """

    parts = source_model.split(".")

    if len(parts) != 3:
        raise ValueError(
            f"Invalid source_model '{source_model}'. "
            "Expected DATABASE.SCHEMA.TABLE"
        )

    return parts[0], parts[1], parts[2]


def quote_list(values: list[str]) -> str:
    """
    Convert:

        ["HK_CUSTOMER", "HK_NATION"]

    into valid Jinja/Python-style list syntax:

        ["HK_CUSTOMER", "HK_NATION"]
    """

    return "[" + ", ".join(f'"{value}"' for value in values) + "]"


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as file:
        file.write(content)


# ==============================================================================
# INITIALISE DIRECTORIES
# ==============================================================================

for directory in [
    STAGING_DIR,
    HUBS_DIR,
    LINKS_DIR,
    SATS_DIR,
]:
    directory.mkdir(parents=True, exist_ok=True)


# ==============================================================================
# REGISTRIES
# ==============================================================================

hubs = {}
links = {}
satellites = {}

sources = {}


# ==============================================================================
# 1. READ METADATA
# ==============================================================================

yaml_files = sorted(METADATA_DIR.glob("*.yml"))

if not yaml_files:
    raise FileNotFoundError(
        f"No metadata files found in {METADATA_DIR}"
    )


for yaml_file in yaml_files:

    metadata = load_yaml(yaml_file)

    source_model = metadata["source_model"]

    source_db, source_schema, source_table = parse_source_model(
        source_model
    )

    # --------------------------------------------------------------------------
    # Register source
    # --------------------------------------------------------------------------

    source_name = source_schema

    sources.setdefault(
        source_name,
        {
            "database": source_db,
            "schema": source_schema,
            "tables": set(),
        },
    )

    sources[source_name]["tables"].add(source_table)

    # --------------------------------------------------------------------------
    # Staging model
    # --------------------------------------------------------------------------

    staging_model = f"stg_{yaml_file.stem.lower()}"

    # --------------------------------------------------------------------------
    # HUBS
    # --------------------------------------------------------------------------

    for hub in metadata.get("hubs", []) or []:

        target_model = hub["target_model"].lower()
        hash_key = hub["hash_key"]

        business_keys = hub["business_keys"]

        if not isinstance(business_keys, dict):
            raise ValueError(
                f"{yaml_file}: business_keys for {target_model} "
                "must be a mapping."
            )

        if target_model not in hubs:
            hubs[target_model] = {
                "hash_key": hash_key,
                "sources": [],
            }

        for standard_name, source_column in business_keys.items():

            source_entry = {
                "staging_model": staging_model,
                "business_key": standard_name,
                "source_column": source_column,
            }

            if source_entry not in hubs[target_model]["sources"]:
                hubs[target_model]["sources"].append(source_entry)

    # --------------------------------------------------------------------------
    # LINKS
    # --------------------------------------------------------------------------

    for link in metadata.get("links", []) or []:

        target_model = link["target_model"].lower()

        if target_model in links:
            existing = links[target_model]

            if existing["hash_key"] != link["hash_key"]:
                raise ValueError(
                    f"Conflicting hash_key for link {target_model}"
                )

        links[target_model] = {
            "hash_key": link["hash_key"],
            "foreign_hash_keys": link["foreign_hash_keys"],
            "staging_model": staging_model,
        }

    # --------------------------------------------------------------------------
    # SATELLITES
    # --------------------------------------------------------------------------

    for satellite in metadata.get("satellites", []) or []:

        target_model = satellite["target_model"].lower()

        if target_model in satellites:
            raise ValueError(
                f"Duplicate satellite definition: {target_model}"
            )

        satellites[target_model] = {
            "parent_hash_key": satellite["parent_hash_key"],
            "diff_hash": satellite["diff_hash"],
            "payload": list(satellite["payload"].keys()),
            "staging_model": staging_model,
        }


# ==============================================================================
# 2. GENERATE STAGING MODELS
# ==============================================================================

for yaml_file in yaml_files:

    metadata = load_yaml(yaml_file)

    source_db, source_schema, source_table = parse_source_model(
        metadata["source_model"]
    )

    staging_model = f"stg_{yaml_file.stem.lower()}"

    derived_columns = {
        "_LOAD_TIMESTAMP": metadata["metadata"]["load_timestamp"],
        "_RECORD_SOURCE": metadata["metadata"]["record_source"],
    }

    hashed_columns = {}

    # --------------------------------------------------------------------------
    # HUB HASH KEYS
    # --------------------------------------------------------------------------

    for hub in metadata.get("hubs", []) or []:

        hash_key = hub["hash_key"]
        business_keys = hub["business_keys"]

        standard_names = []

        for standard_name, source_column in business_keys.items():

            derived_columns[standard_name] = source_column
            standard_names.append(standard_name)

        # A single business key can be a string; a composite key must be a list.
        hashed_columns[hash_key] = (
            standard_names[0]
            if len(standard_names) == 1
            else standard_names
        )

    # --------------------------------------------------------------------------
    # LINK HASH KEYS
    # --------------------------------------------------------------------------

    for link in metadata.get("links", []) or []:

        hashed_columns[link["hash_key"]] = link["foreign_hash_keys"]

    # --------------------------------------------------------------------------
    # SATELLITE HASHDIFFS
    # --------------------------------------------------------------------------

    for satellite in metadata.get("satellites", []) or []:

        diff_hash = satellite["diff_hash"]

        payload = satellite["payload"]

        if diff_hash in hashed_columns:
            raise ValueError(
                f"Hashdiff '{diff_hash}' is defined more than once "
                f"with different metadata. "
                f"Check {yaml_file}."
            )

        hashed_columns[diff_hash] = {
            "is_hashdiff": True,
            "columns": list(payload.keys()),
        }

        for standard_name, source_column in payload.items():
            derived_columns[standard_name] = source_column

    # --------------------------------------------------------------------------
    # Build YAML metadata for AutomateDV
    # --------------------------------------------------------------------------

    derived_yaml = "\n".join(
        f'  {name}: "{expression}"'
        for name, expression in derived_columns.items()
    )

    hashed_yaml_parts = []

    for hash_name, definition in hashed_columns.items():

        if isinstance(definition, dict):

            hashed_yaml_parts.append(
                f"""  {hash_name}:
    is_hashdiff: true
    columns:
"""
                + "\n".join(
                    f'      - "{column}"'
                    for column in definition["columns"]
                )
            )

        elif isinstance(definition, list):

            hashed_yaml_parts.append(
                f"""  {hash_name}:
"""
                + "\n".join(
                    f'    - "{column}"'
                    for column in definition
                )
            )

        else:

            hashed_yaml_parts.append(
                f'  {hash_name}: "{definition}"'
            )

    hashed_yaml = "\n".join(hashed_yaml_parts)

    # AutomateDV source-style mapping
    source_mapping = f'  {source_schema}: "{source_table}"'

    staging_sql = f"""

{{% set yaml_metadata %}}
source_model:
{source_mapping}

derived_columns:
{derived_yaml}

hashed_columns:
{hashed_yaml}
{{% endset %}}

{{% set metadata_dict = fromyaml(yaml_metadata) %}}

{{{{ automate_dv.stage(
    source_model=metadata_dict['source_model'],
    derived_columns=metadata_dict['derived_columns'],
    hashed_columns=metadata_dict['hashed_columns']
) }}}}
"""

    write_file(
        STAGING_DIR / f"{staging_model}.sql",
        staging_sql,
    )


# ==============================================================================
# 3. GENERATE HUBS
# ==============================================================================

for hub_name, hub in hubs.items():

    hash_key = hub["hash_key"]
    sources_for_hub = hub["sources"]

    staging_models = list(dict.fromkeys(
        source["staging_model"]
        for source in sources_for_hub
    ))

    business_keys = list(dict.fromkeys(
        source["business_key"]
        for source in sources_for_hub
    ))

    if len(staging_models) == 1:
        source_model = f'"{staging_models[0]}"'
    else:
        source_model = quote_list(staging_models)

    if len(business_keys) == 1:
        src_nk = f'"{business_keys[0]}"'
    else:
        src_nk = quote_list(business_keys)

    hub_sql = f"""
{{{{ automate_dv.hub(
    src_pk="{hash_key}",
    src_nk={src_nk},
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model={source_model}
) }}}}
"""

    write_file(
        HUBS_DIR / f"{hub_name}.sql",
        hub_sql,
    )


# ==============================================================================
# 4. GENERATE LINKS
# ==============================================================================

for link_name, link in links.items():

    src_fk = quote_list(link["foreign_hash_keys"])

    link_sql = f"""
{{{{ automate_dv.link(
    src_pk="{link['hash_key']}",
    src_fk={src_fk},
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="{link['staging_model']}"
) }}}}
"""

    write_file(
        LINKS_DIR / f"{link_name}.sql",
        link_sql,
    )


# ==============================================================================
# 5. GENERATE SATELLITES
# ==============================================================================

for satellite_name, satellite in satellites.items():

    src_payload = quote_list(satellite["payload"])

    satellite_sql = f"""
{{{{ automate_dv.sat(
    src_pk="{satellite['parent_hash_key']}",
    src_hashdiff="{satellite['diff_hash']}",
    src_payload={src_payload},
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="{satellite['staging_model']}"
) }}}}
"""

    write_file(
        SATS_DIR / f"{satellite_name}.sql",
        satellite_sql,
    )


# ==============================================================================
# 6. GENERATE SOURCES.YML
# ==============================================================================

source_definitions = []

for source_name, source in sources.items():

    source_definitions.append(
        {
            "name": source_name,
            "database": source["database"],
            "schema": source["schema"],
            "tables": [
                {"name": table}
                for table in sorted(source["tables"])
            ],
        }
    )


sources_yaml = {
    "version": 2,
    "sources": source_definitions,
}


SOURCES_FILE.parent.mkdir(parents=True, exist_ok=True)

with SOURCES_FILE.open("w", encoding="utf-8") as file:
    yaml.dump(
        sources_yaml,
        file,
        sort_keys=False,
        default_flow_style=False,
    )


# ==============================================================================
# SUMMARY
# ==============================================================================

print(f"Processed {len(yaml_files)} metadata files.")

print(f"Generated {len(yaml_files)} staging models.")
print(f"Generated {len(hubs)} hub models.")
print(f"Generated {len(links)} link models.")
print(f"Generated {len(satellites)} satellite models.")

print(f"Sources written to: {SOURCES_FILE}")