
{{ automate_dv.link(
    src_pk="HK_LNK_ORDER_CUSTOMER",
    src_fk=["HK_ORDER", "HK_CUSTOMER"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_orders"
) }}
