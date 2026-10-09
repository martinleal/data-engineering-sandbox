
{{ automate_dv.hub(
    src_pk="HK_NATION",
    src_nk="ID_NATION",
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model=["stg_customer", "stg_nation", "stg_supplier"]
) }}
