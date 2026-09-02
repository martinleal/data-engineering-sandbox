{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_SUPPLIER"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_SUPPLIER: "S_SUPPKEY"
  ID_NATION: "S_NATIONKEY"
  NAME: "S_NAME"
  ADDRESS: "S_ADDRESS"
  PHONE: "S_PHONE"
  COMMENT: "S_COMMENT"
  ACCTBAL: "S_ACCTBAL"
hashed_columns:
  HK_SUPPLIER: "ID_SUPPLIER"
  HK_NATION: "ID_NATION"
  HK_LNK_SUPPLIER_NATION:
      - "HK_SUPPLIER"
      - "HK_NATION"
  HD_SUPPLIER:
    is_hashdiff: true
    columns:
      - "ACCTBAL"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
