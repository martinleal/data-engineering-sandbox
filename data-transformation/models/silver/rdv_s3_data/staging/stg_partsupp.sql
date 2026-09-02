{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_PARTSUPP"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_PRODUCT: "PS_PARTKEY"
  ID_SUPPLIER: "PS_SUPPKEY"
  AVAILQTY: "PS_AVAILQTY"
  SUPPLYCOST: "PS_SUPPLYCOST"
  COMMENT: "PS_COMMENT"
hashed_columns:
  HK_PRODUCT: "ID_PRODUCT"
  HK_SUPPLIER: "ID_SUPPLIER"
  HK_LNK_PRODUCT_SUPPLIER:
      - "HK_PRODUCT"
      - "HK_SUPPLIER"
  HD_PRODUCT_SUPPLIER:
    is_hashdiff: true
    columns:
      - "AVAILQTY"
      - "SUPPLYCOST"
      - "COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
