{{ config(materialized='view') }}

{{ dbtvault.sat(src_pk="HK_ORDER",
                  src_hashdiff="HD_ORDER",
                  src_payload=["ORDERSTATUS", "TOTALPRICE", "ORDERDATE", "ORDERPRIORITY", "CLERK", "SHIPPRIORITY", "COMMENT"],
                  src_ldts="_LOAD_TIMESTAMP",
                  src_source="_RECORD_SOURCE",
                  source_model="stg_orders") }}
