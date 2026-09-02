{{ config(materialized='view') }}

{{ dbtvault.hub(src_pk="HK_SUPPLIER",
                src_nk="ID_SUPPLIER",
                src_ldts="_LOAD_TIMESTAMP",
                src_source="_RECORD_SOURCE",
                source_model=["stg_lineitem", "stg_partsupp", "stg_supplier"]) }}
