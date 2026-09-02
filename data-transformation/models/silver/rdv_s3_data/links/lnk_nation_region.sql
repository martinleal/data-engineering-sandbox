{{ config(materialized='view') }}

{{ dbtvault.link(src_pk="HK_LNK_NATION_REGION",
                   src_fk=["HK_NATION", "HK_REGION"],
                   src_ldts="_LOAD_TIMESTAMP",
                   src_source="_RECORD_SOURCE",
                   source_model="stg_nation") }}
