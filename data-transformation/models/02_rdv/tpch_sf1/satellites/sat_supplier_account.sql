
{{ automate_dv.sat(
    src_pk="HK_SUPPLIER",
    src_hashdiff="HD_SUPPLIER_ACCOUNT",
    src_payload=["ACCTBAL"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_supplier"
) }}
