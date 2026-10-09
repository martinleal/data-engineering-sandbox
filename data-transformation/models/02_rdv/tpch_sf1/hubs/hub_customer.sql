
{{ automate_dv.hub(
    src_pk="HK_CUSTOMER",
    src_nk="ID_CUSTOMER",
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model=["stg_customer", "stg_orders"]
) }}
