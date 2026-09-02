{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model:
  BRONZE__S3_DATA: "TB_LINEITEM"
derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_ORDER: "L_ORDERKEY"
  ID_ORDER_LINE: "L_LINENUMBER"
  ID_PRODUCT: "L_PARTKEY"
  ID_SUPPLIER: "L_SUPPKEY"
  QUANTITY: "L_QUANTITY"
  EXTENDEDPRICE: "L_EXTENDEDPRICE"
  DISCOUNT: "L_DISCOUNT"
  TAX: "L_TAX"
  RETURNFLAG: "L_RETURNFLAG"
  LINESTATUS: "L_LINESTATUS"
  SHIPDATE: "L_SHIPDATE"
  COMMITDATE: "L_COMMITDATE"
  RECEIPTDATE: "L_RECEIPTDATE"
  SHIPINSTRUCT: "L_SHIPINSTRUCT"
  SHIPMODE: "L_SHIPMODE"
hashed_columns:
  HK_ORDER_LINE: "ID_ORDER"
  HK_ORDER: "ID_ORDER"
  HK_PRODUCT: "ID_PRODUCT"
  HK_SUPPLIER: "ID_SUPPLIER"
  HK_LNK_ORDER_LINE:
      - "HK_ORDER_LINE"
      - "HK_ORDER"
  HK_LNK_ORDER_LINE_PRODUCT_SUPPLIER:
      - "HK_ORDER_LINE"
      - "HK_ORDER"
      - "HK_PRODUCT"
      - "HK_SUPPLIER"
  HD_ORDER_LINE_FINANCE:
    is_hashdiff: true
    columns:
      - "QUANTITY"
      - "EXTENDEDPRICE"
      - "DISCOUNT"
      - "TAX"
  HD_ORDER_LINE_LOGISTICS:
    is_hashdiff: true
    columns:
      - "RETURNFLAG"
      - "LINESTATUS"
      - "SHIPDATE"
      - "COMMITDATE"
      - "RECEIPTDATE"
      - "SHIPINSTRUCT"
      - "SHIPMODE"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.stage(source_model=metadata_dict['source_model'],
                  derived_columns=metadata_dict['derived_columns'],
                  hashed_columns=metadata_dict['hashed_columns']) }}
