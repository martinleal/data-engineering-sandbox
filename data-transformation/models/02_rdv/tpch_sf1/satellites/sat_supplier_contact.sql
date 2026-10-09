
{{ automate_dv.sat(
    src_pk="HK_SUPPLIER",
    src_hashdiff="HD_SUPPLIER_CONTACT",
    src_payload=["NAME", "ADDRESS", "PHONE", "COMMENT"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_supplier"
) }}
