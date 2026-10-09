
{{ automate_dv.sat(
    src_pk="HK_LNK_PRODUCT_SUPPLIER",
    src_hashdiff="HD_PRODUCT_SUPPLIER",
    src_payload=["AVAILQTY", "SUPPLYCOST", "COMMENT"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_partsupp"
) }}
