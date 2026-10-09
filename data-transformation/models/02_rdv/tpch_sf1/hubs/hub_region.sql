
{{ automate_dv.hub(
    src_pk="HK_REGION",
    src_nk="ID_REGION",
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model=["stg_nation", "stg_region"]
) }}
