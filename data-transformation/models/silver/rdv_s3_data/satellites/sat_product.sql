{{ config(materialized='view') }}

{{ dbtvault.sat(src_pk="HK_PRODUCT",
                  src_hashdiff="HD_PRODUCT",
                  src_payload=["NAME", "MFGR", "BRAND", "TYPE", "SIZE", "CONTAINER", "RETAILPRICE", "COMMENT"],
                  src_ldts="_LOAD_TIMESTAMP",
                  src_source="_RECORD_SOURCE",
                  source_model="stg_part") }}
