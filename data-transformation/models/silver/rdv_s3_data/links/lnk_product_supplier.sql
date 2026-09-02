{{ config(materialized='view') }}

{{ dbtvault.link(src_pk="HK_LNK_PRODUCT_SUPPLIER",
                   src_fk=["HK_PRODUCT", "HK_SUPPLIER"],
                   src_ldts="_LOAD_TIMESTAMP",
                   src_source="_RECORD_SOURCE",
                   source_model="stg_partsupp") }}
