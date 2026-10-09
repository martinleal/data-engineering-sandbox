
{{ automate_dv.link(
    src_pk="HK_LNK_ORDER_LINE_PRODUCT_SUPPLIER",
    src_fk=["HK_ORDER_LINE", "HK_ORDER", "HK_PRODUCT", "HK_SUPPLIER"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_lineitem"
) }}
