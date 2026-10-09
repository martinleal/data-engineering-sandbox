
{{ automate_dv.sat(
    src_pk="HK_NATION",
    src_hashdiff="HD_NATION",
    src_payload=["NAME", "COMMENT"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_nation"
) }}
