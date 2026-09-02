{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_REGION"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_REGION: "R_REGIONKEY"
  NAME: "R_NAME"
  COMMENT: "R_COMMENT"
hashed_columns:
  HK_REGION: "ID_REGION"
  HD_REGION:
    is_hashdiff: true
    columns:
      - "NAME"
      - "COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
