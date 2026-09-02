{{ config(materialized='view') }}

{{ dbtvault.sat(src_pk="HK_CUSTOMER",
                  src_hashdiff="HD_CUSTOMER",
                  src_payload=["ACCTBAL", "MKTSEGMENT"],
                  src_ldts="_LOAD_TIMESTAMP",
                  src_source="_RECORD_SOURCE",
                  source_model="stg_customer") }}
