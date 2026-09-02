{{ config(materialized='view') }}

{{ dbtvault.sat(src_pk="HK_ORDER_LINE",
                  src_hashdiff="HD_ORDER_LINE_FINANCE",
                  src_payload=["QUANTITY", "EXTENDEDPRICE", "DISCOUNT", "TAX"],
                  src_ldts="_LOAD_TIMESTAMP",
                  src_source="_RECORD_SOURCE",
                  source_model="stg_lineitem") }}
