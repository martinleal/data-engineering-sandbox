

{% set yaml_metadata %}
source_model:
  TPCH_SF1: "NATION"

derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_NATION: "N_NATIONKEY"
  ID_REGION: "N_REGIONKEY"
  NAME: "N_NAME"
  COMMENT: "N_COMMENT"

hashed_columns:
  HK_NATION: "ID_NATION"
  HK_REGION: "ID_REGION"
  HK_LNK_NATION_REGION:
    - "HK_NATION"
    - "HK_REGION"
  HD_NATION:
    is_hashdiff: true
    columns:
      - "NAME"
      - "COMMENT"
{% endset %}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(
    source_model=metadata_dict['source_model'],
    derived_columns=metadata_dict['derived_columns'],
    hashed_columns=metadata_dict['hashed_columns']
) }}
