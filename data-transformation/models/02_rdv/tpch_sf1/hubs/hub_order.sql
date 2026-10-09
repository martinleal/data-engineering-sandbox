
{{ automate_dv.hub(
    src_pk="HK_ORDER",
    src_nk="ID_ORDER",
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model=["stg_lineitem", "stg_orders"]
) }}
