{{ config(materialized='view') }}

{{ dbtvault.link(src_pk="HK_LNK_CUSTOMER_NATION",
                   src_fk=["HK_CUSTOMER", "HK_NATION"],
                   src_ldts="_LOAD_TIMESTAMP",
                   src_source="_RECORD_SOURCE",
                   source_model="stg_customer") }}
