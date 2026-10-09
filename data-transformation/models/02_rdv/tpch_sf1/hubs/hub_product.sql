
{{ automate_dv.hub(
    src_pk="HK_PRODUCT",
    src_nk="ID_PRODUCT",
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model=["stg_lineitem", "stg_part", "stg_partsupp"]
) }}
