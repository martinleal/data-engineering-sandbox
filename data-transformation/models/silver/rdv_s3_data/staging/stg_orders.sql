{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_ORDERS"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_ORDER: "O_ORDERKEY"
  ID_CUSTOMER: "O_CUSTKEY"
  ORDERSTATUS: "O_ORDERSTATUS"
  TOTALPRICE: "O_TOTALPRICE"
  ORDERDATE: "O_ORDERDATE"
  ORDERPRIORITY: "O_ORDERPRIORITY"
  CLERK: "O_CLERK"
  SHIPPRIORITY: "O_SHIPPRIORITY"
  COMMENT: "O_COMMENT"
hashed_columns:
  HK_ORDER: "ID_ORDER"
  HK_CUSTOMER: "ID_CUSTOMER"
  HK_LNK_ORDER_CUSTOMER:
      - "HK_ORDER"
      - "HK_CUSTOMER"
  HD_ORDER:
    is_hashdiff: true
    columns:
      - "ORDERSTATUS"
      - "TOTALPRICE"
      - "ORDERDATE"
      - "ORDERPRIORITY"
      - "CLERK"
      - "SHIPPRIORITY"
      - "COMMENT"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
