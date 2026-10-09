
{{ automate_dv.link(
    src_pk="HK_LNK_SUPPLIER_NATION",
    src_fk=["HK_SUPPLIER", "HK_NATION"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_supplier"
) }}
