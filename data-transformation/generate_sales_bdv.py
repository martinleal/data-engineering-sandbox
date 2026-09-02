import glob
import os
import yaml

# Directorios de destino para la capa BDV
hubs_folder = 'models/gold_sales/bdv/hubs'
links_folder = 'models/gold_sales/bdv/links'
bsats_folder = 'models/gold_sales/bdv/bsatellites'
pits_folder = 'models/gold_sales/bdv/pits'
bridges_folder = 'models/gold_sales/bdv/bridges'

DIRS = [
    hubs_folder,
    links_folder,
    bsats_folder,
    pits_folder,
    bridges_folder
]
for d in DIRS:
    os.makedirs(d, exist_ok=True)
bdv_yaml_pattern = os.path.join("mappings/gold_sales", "bdv", "*.yml")
bdv_yaml_files = glob.glob(bdv_yaml_pattern)

if not bdv_yaml_files:
    print("Advertencia: No se encontraron archivos .yml en 'mappings/bdv/'")

# ------------------------------------------------------------------------------
# FUNCIONES GENERADORAS
# ------------------------------------------------------------------------------

def process_satellite(data):
    if not isinstance(data, dict):
        return

    raw_target = data.get("target_model") or data.get("satellite_name")
    if not raw_target or not str(raw_target).upper().startswith("BSAT_"):
        return

    raw_target = str(raw_target).lower()
    target = raw_target if raw_target.startswith("b") else f"b{raw_target}"
    
    schema = data.get("config", {}).get("schema", "BDV_SALES")
    mat = data.get("config", {}).get("materialization", "incremental")

    hash_key = data.get("hash_key", "HK_UNKNOWN")
    diff_hash = data.get("diff_hash", "HD_UNKNOWN")
    sources = [s.lower() for s in data.get("source_models", [])]
    
    raw_source = sources[0] if sources else "unknown_source"
    source_ref = raw_source.split(".")[-1]

    payload_exprs = []
    payload_cols = []
    for p in data.get("payload", []):
        target_col = p.get("target_column")
        source_expr = p.get("source_expression")
        if target_col and source_expr:
            payload_exprs.append(f"        {source_expr} AS {target_col}")
            payload_cols.append(target_col)

    payload_select_str = ",\n".join(payload_exprs)
    payload_cols_str = ",\n        ".join(payload_cols) if payload_cols else ""

    sql_content = f"""{{{{ config(materialized='{mat}', schema='{schema}') }}}}

WITH source_data AS (
    SELECT 
        {hash_key},
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
{payload_select_str}
    FROM {{{{ ref('{source_ref}') }}}}
),

stage_bdv AS (
    SELECT
        {hash_key},
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{{{ dbt_utils.generate_surrogate_key({payload_cols}) }}}} AS {diff_hash},
        {payload_cols_str}        
    FROM source_data
)

SELECT * FROM stage_bdv
"""
    with open(f"{bsats_folder}/{target}.sql", "w", encoding="utf-8") as out:
        out.write(sql_content)


def process_pit(data):
    if not isinstance(data, dict):
        return

    raw_target = data.get("target_model", "").lower()
    if not raw_target:
        return

    target = raw_target if raw_target.startswith("b") else f"b{raw_target}"
    
    schema = data.get("config", {}).get("schema", "BDV_SALES")
    mat = data.get("config", {}).get("materialization", "incremental")

    parent_hub = data.get("parent_hub", "hub_unknown").split(".")[-1].lower()
    
    # Inferencia de hash_key a partir del parent_hub si no viene explícita
    hash_key = data.get("hash_key")
    if not hash_key:
        hub_clean = parent_hub.replace("hub_", "").upper()
        hash_key = f"HK_{hub_clean}"

    as_of_dates_table = data.get("as_of_date_table", "as_of_date").lower()

    sats_list = data.get("satellites") or data.get("tracked_satellites") or []
    
    sat_dict = {}
    stage_sats_dict = {}

    for sat in sats_list:
        if isinstance(sat, dict):
            raw_sat_name = (sat.get("table") or sat.get("satellite_name") or "").lower()
            sat_ref_name = f"b{raw_sat_name}" if raw_sat_name.startswith("bsat_") else raw_sat_name

            hk_col = sat.get("hk_column") or sat.get("pk_key") or hash_key
            ts_col = sat.get("ts_column") or sat.get("ldts") or "_LOAD_TIMESTAMP"

            if sat_ref_name:
                sat_dict[sat_ref_name] = {
                    "pk": {"pk_col": hk_col},
                    "ldts": {"ldts_col": ts_col}
                }
                stage_sats_dict[sat_ref_name] = {
                    "hk_col": hk_col,
                    "ldts_col": ts_col
                }

    sql_content = f"""{{{{ config(materialized='{mat}', schema='{schema}') }}}}

{{%- set yaml_metadata -%}}
source_model: "{parent_hub}"
src_pk: "{hash_key}"
as_of_dates_table: "{as_of_dates_table}"
satellites:
  {yaml.dump(sat_dict, indent=4).replace("'", '"').strip()}
stage_tables_ldts:
  {yaml.dump(stage_sats_dict, indent=4).replace("'", '"').strip()}
src_ldts: "_LOAD_TIMESTAMP"
{{%- endset -%}}

{{% set metadata_dict = fromyaml(yaml_metadata) %}}

{{{{ dbtvault.pit(source_model=metadata_dict['source_model'],
                 src_pk=metadata_dict['src_pk'],
                 as_of_dates_table=metadata_dict['as_of_dates_table'],
                 satellites=metadata_dict['satellites'],
                 stage_tables_ldts=metadata_dict['stage_tables_ldts'],
                 src_ldts=metadata_dict['src_ldts']) }}}}
"""
    with open(f"{pits_folder}/{target}.sql", "w", encoding="utf-8") as out:
        out.write(sql_content)
# ------------------------------------------------------------------------------
# GENERACIÓN AUTOMÁTICA DEL MODELO AUXILIAR AS_OF_DATE PARA PITS
# ------------------------------------------------------------------------------
as_of_date_path = "models/gold_sales/bdv/as_of_date.sql"

if not os.path.exists(as_of_date_path):
    as_of_date_sql = """{{ config(materialized='table', schema='BDV_SALES') }}

WITH date_spine AS (
    SELECT 
        DATEADD(day, seq4(), '2020-01-01'::DATE) AS AS_OF_DATE
    FROM TABLE(GENERATOR(ROWCOUNT => 365 * 10))
)

SELECT 
    AS_OF_DATE
FROM date_spine
WHERE AS_OF_DATE <= CURRENT_DATE()
"""
    with open(as_of_date_path, "w", encoding="utf-8") as out:
        out.write(as_of_date_sql)
    print("Modelo de apoyo 'as_of_date.sql' creado exitosamente.")


def process_bridge(data):
    if not isinstance(data, dict):
        return

    raw_target = data.get("target_model", "").lower()
    if not raw_target:
        return

    target = raw_target if raw_target.startswith("b") else f"b{raw_target}"
    
    schema = data.get("config", {}).get("schema", "BDV_SALES")
    mat = data.get("config", {}).get("materialization", "table")

    bridge_keys = data.get("bridge_keys", [])
    join_path = data.get("join_path", [])

    joins_list = []
    from_clause = ""

    for idx, jp in enumerate(join_path):
        tbl = jp.get("table", "").split(".")[-1].lower()
        alias = jp.get("alias", f"t{idx}")
        if idx == 0:
            from_clause = f"FROM {{{{ ref('{tbl}') }}}} {alias}"
        else:
            join_on = jp.get("join_on", "")
            joins_list.append(f"LEFT JOIN {{{{ ref('{tbl}') }}}} {alias}\n    ON {join_on}")

    joins_str = "\n".join(joins_list)
    select_keys_str = ",\n    ".join(bridge_keys) if bridge_keys else "*"

    sql_content = f"""{{{{ config(materialized='{mat}', schema='{schema}') }}}}

SELECT
    {select_keys_str}
{from_clause}
{joins_str}
"""
    with open(f"{bridges_folder}/{target}.sql", "w", encoding="utf-8") as out:
        out.write(sql_content)

# ------------------------------------------------------------------------------
# PROCESAMIENTO CON PRIORIDAD DE ESTRUCTURA PLANA
# ------------------------------------------------------------------------------

for file_path in bdv_yaml_files:
    with open(file_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    if not data or not isinstance(data, dict):
        continue

    # 1. ARCHIVOS CON target_model EN LA RAÍZ (Prioridad máxima para evitar falsos positivos)
    if "target_model" in data:
        target_upper = str(data["target_model"]).upper()
        if target_upper.startswith("BSAT_"):
            process_satellite(data)
        elif target_upper.startswith("PIT_"):
            process_pit(data)
        elif target_upper.startswith("BRG_") or target_upper.startswith("BRIDGE_"):
            process_bridge(data)

    # 2. CONTENEDORES EN LISTA
    elif "hubs" in data:
        schema = data.get("config", {}).get("schema", "BDV_SALES")
        mat = data.get("config", {}).get("materialization", "view")

        for hub_item in data["hubs"]:
            raw_target = hub_item.get("target_model", "").lower()
            if not raw_target:
                continue
            target = raw_target if raw_target.startswith("b") else f"b{raw_target}"
            source_raw = hub_item.get("source_model", "").split(".")[-1].lower()

            sql_content = f"""{{{{ config(materialized='{mat}', schema='{schema}') }}}}

SELECT * 
FROM {{{{ ref('{source_raw}') }}}}
"""
            with open(f"{hubs_folder}/{target}.sql", "w", encoding="utf-8") as out:
                out.write(sql_content)

    elif "links" in data:
        schema = data.get("config", {}).get("schema", "BDV_SALES")
        mat = data.get("config", {}).get("materialization", "view")

        for link_item in data["links"]:
            raw_target = link_item.get("target_model", "").lower()
            if not raw_target:
                continue
            target = raw_target if raw_target.startswith("b") else f"b{raw_target}"
            source_raw = link_item.get("source_model", "").split(".")[-1].lower()

            sql_content = f"""{{{{ config(materialized='{mat}', schema='{schema}') }}}}

SELECT * 
FROM {{{{ ref('{source_raw}') }}}}
"""
            with open(f"{links_folder}/{target}.sql", "w", encoding="utf-8") as out:
                out.write(sql_content)

    elif "bridges" in data:
        for bridge_item in data["bridges"]:
            if isinstance(bridge_item, dict):
                if "config" in data and "config" not in bridge_item:
                    bridge_item["config"] = data["config"]
                process_bridge(bridge_item)

    elif "pits" in data:
        for pit_item in data["pits"]:
            if isinstance(pit_item, dict):
                if "config" in data and "config" not in pit_item:
                    pit_item["config"] = data["config"]
                process_pit(pit_item)

    elif "satellites" in data:
        for sat_item in data["satellites"]:
            if isinstance(sat_item, dict):
                if "config" in data and "config" not in sat_item:
                    sat_item["config"] = data["config"]
                process_satellite(sat_item)

print("Modelos Business Data Vault generados exitosamente en models/gold_sales/bdv/")