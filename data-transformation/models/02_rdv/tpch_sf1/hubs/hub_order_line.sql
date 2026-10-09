
{{ automate_dv.hub(
    src_pk="HK_ORDER_LINE",
    src_nk=["ID_ORDER", "ID_ORDER_LINE"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_lineitem"
) }}
