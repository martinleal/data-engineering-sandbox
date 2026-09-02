import glob
import os
import yaml

# Directorios de la capa Silver (Staging y Raw Vault)
staging_folder = 'models/silver/rdv_s3_data/staging'
hubs_folder = 'models/silver/rdv_s3_data/hubs'
links_folder = 'models/silver/rdv_s3_data/links'
sats_folder = 'models/silver/rdv_s3_data/satellites'
DIRS = [
    staging_folder,
    hubs_folder,
    links_folder,
    sats_folder,
]
for d in DIRS:
    os.makedirs(d, exist_ok=True)

hubs_registry = {}
links_registry = {}
satellites_registry = {}
sources_tables = []

# ------------------------------------------------------------------------------
# 1. PARSEAR MAPPINGS Y GENERAR CAPA DE STAGING (CON HASHES)
# ------------------------------------------------------------------------------
yaml_pattern = os.path.join("mappings/silver/rdv_s3_data", "*.yml")
yaml_files = glob.glob(yaml_pattern)

if not yaml_files:
    print("Advertencia: No se encontraron archivos .yml en 'mappings/'")

for file_path in yaml_files:
    with open(file_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    if not data:
        continue

    base_name = os.path.splitext(os.path.basename(file_path))[0]
    clean_name = base_name.split("(")[0].strip().lower()
    stg_name = f"stg_{clean_name}"

    full_source = data.get("source_model", "")
    parts = full_source.split('.')

    # Assign the variables based on their position
    source_db = parts[0]
    source_schema = parts[1]
    source_table = parts[2]

    if source_table not in sources_tables:
        sources_tables.append(source_table)

    derived_cols = {
        "_LOAD_TIMESTAMP": "_LOAD_TIMESTAMP",
        "_RECORD_SOURCE": "_RECORD_SOURCE",
    }
    hashed_cols = {}

    # Procesar HUBS
    for hub in data.get("hubs", []) or []:
        target = hub["target_model"].lower()
        hash_key = hub["hash_key"]
        bk_dict = hub["business_keys"]

        if isinstance(bk_dict, dict):
            for std_name, orig_col in bk_dict.items():
                derived_cols[std_name] = orig_col
                if hash_key not in hashed_cols:
                    hashed_cols[hash_key] = std_name
                bk_std = std_name
        else:
            hashed_cols[hash_key] = bk_dict
            bk_std = bk_dict

        if target not in hubs_registry:
            hubs_registry[target] = {
                "hash_key": hash_key,
                "sources": {}
            }
        hubs_registry[target]["sources"][stg_name] = bk_std

    # Procesar LINKS
    for link in data.get("links", []) or []:
        target = link["target_model"].lower()
        hash_key = link["hash_key"]
        fk_keys = link["foreign_hash_keys"]

        if hash_key not in hashed_cols:
            hashed_cols[hash_key] = fk_keys

        links_registry[target] = {
            "hash_key": hash_key,
            "fk_keys": fk_keys,
            "stg": stg_name,
        }

    # Procesar SATELLITES
    for sat in data.get("satellites", []) or []:
        target = sat["target_model"].lower()
        parent_pk = sat["parent_hash_key"]
        diff_hash = sat["diff_hash"]
        payload_dict = sat["payload"]

        payload_cols = []
        if isinstance(payload_dict, dict):
            for std_name, orig_col in payload_dict.items():
                derived_cols[std_name] = orig_col
                payload_cols.append(std_name)
        elif isinstance(payload_dict, list):
            payload_cols = payload_dict

        hashed_cols[diff_hash] = {
            "is_hashdiff": True,
            "columns": payload_cols,
        }

        satellites_registry[target] = {
            "parent_pk": parent_pk,
            "diff_hash": diff_hash,
            "payload": payload_cols,
            "stg": stg_name,
        }

    # Generar SQL de la vista Staging
    derived_yaml_str = "\n".join([f'  {k}: "{v}"' for k, v in derived_cols.items()])
    
    hashed_lines = []
    for hk, val in hashed_cols.items():
        if isinstance(val, dict) and val.get("is_hashdiff"):
            cols_str = "\n".join([f'      - "{c}"' for c in val["columns"]])
            hashed_lines.append(f'  {hk}:\n    is_hashdiff: true\n    columns:\n{cols_str}')
        elif isinstance(val, list):
            cols_str = "\n".join([f'      - "{c}"' for c in val])
            hashed_lines.append(f'  {hk}:\n{cols_str}')
        else:
            hashed_lines.append(f'  {hk}: "{val}"')
    hashed_yaml_str = "\n".join(hashed_lines)

    stg_sql_content = f"""{{{{ config(materialized='view') }}}}

{{%- set yaml_metadata -%}}
source_model:
  {source_db}__{source_schema}: "{source_table}"
derived_columns:
{derived_yaml_str}
hashed_columns:
{hashed_yaml_str}
{{%- endset -%}}

{{% set metadata_dict = fromyaml(yaml_metadata) %}}

{{{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}}}
"""
    with open(f"{staging_folder}/{stg_name}.sql", "w", encoding="utf-8") as out:
        out.write(stg_sql_content)

print(f"Se generaron vistas Staging en {staging_folder}")

# ------------------------------------------------------------------------------
# 2. GENERAR SOURCES.YML
# ------------------------------------------------------------------------------
sources_yaml_data = {
    "version": 2,
    "sources": [
        {
            "name": f"{source_db}__{source_schema}",
            "database": f"{source_db}",
            "schema": f"{source_schema}",
            "tables": [{"name": table_name} for table_name in sources_tables]
        }
    ]
}

with open("models/silver/sources.yml", "w", encoding="utf-8") as out_sources:
    yaml.dump(sources_yaml_data, out_sources, default_flow_style=False, sort_keys=False)

# ------------------------------------------------------------------------------
# 3. GENERAR HUBS, LINKS Y SATELLITES REFERENCIANDO LAS STAGINGS (STRINGS)
# ------------------------------------------------------------------------------
# HUBS
for hub_name, hub_info in hubs_registry.items():
    sources_list = list(hub_info["sources"].keys())
    bk_unificada = list(hub_info["sources"].values())[0]

    src_model_param = (
        f'"{sources_list[0]}"'
        if len(sources_list) == 1
        else str(sources_list).replace("'", '"')
    )

    hub_sql_content = f"""{{{{ config(materialized='view') }}}}

{{{{ dbtvault.hub(src_pk="{hub_info['hash_key']}",
                src_nk="{bk_unificada}",
                src_ldts="_LOAD_TIMESTAMP",
                src_source="_RECORD_SOURCE",
                source_model={src_model_param}) }}}}
"""
    with open(f"{hubs_folder}/{hub_name}.sql", "w", encoding="utf-8") as out:
        out.write(hub_sql_content)

# LINKS
for link_name, link_info in links_registry.items():
    fk_list_str = str(link_info["fk_keys"]).replace("'", '"')
    link_sql_content = f"""{{{{ config(materialized='view') }}}}

{{{{ dbtvault.link(src_pk="{link_info['hash_key']}",
                   src_fk={fk_list_str},
                   src_ldts="_LOAD_TIMESTAMP",
                   src_source="_RECORD_SOURCE",
                   source_model="{link_info['stg']}") }}}}
"""
    with open(f"{links_folder}/{link_name}.sql", "w", encoding="utf-8") as out:
        out.write(link_sql_content)

# SATELLITES
for sat_name, sat_info in satellites_registry.items():
    payload_str = str(sat_info["payload"]).replace("'", '"')
    sat_sql_content = f"""{{{{ config(materialized='view') }}}}

{{{{ dbtvault.sat(src_pk="{sat_info['parent_pk']}",
                  src_hashdiff="{sat_info['diff_hash']}",
                  src_payload={payload_str},
                  src_ldts="_LOAD_TIMESTAMP",
                  src_source="_RECORD_SOURCE",
                  source_model="{sat_info['stg']}") }}}}
"""
    with open(f"{sats_folder}/{sat_name}.sql", "w", encoding="utf-8") as out:
        out.write(sat_sql_content)

print("Hubs, Links y Satélites generados correctamente en models/silver/rdv/")