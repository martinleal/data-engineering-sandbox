{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_CUSTOMER"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_CUSTOMER: "C_CUSTKEY"
  ID_NATION: "C_NATIONKEY"
  NAME: "C_NAME"
  ADDRESS: "C_ADDRESS"
  PHONE: "C_PHONE"
  COMMENT: "C_COMMENT"
  ACCTBAL: "C_ACCTBAL"
  MKTSEGMENT: "C_MKTSEGMENT"
hashed_columns:
  HK_CUSTOMER: "ID_CUSTOMER"
  HK_NATION: "ID_NATION"
  HK_LNK_CUSTOMER_NATION:
      - "HK_CUSTOMER"
      - "HK_NATION"
  HD_CUSTOMER:
    is_hashdiff: true
    columns:
      - "ACCTBAL"
      - "MKTSEGMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
