
{{ automate_dv.sat(
    src_pk="HK_ORDER_LINE",
    src_hashdiff="HD_ORDER_LINE_LOGISTICS",
    src_payload=["RETURNFLAG", "LINESTATUS", "SHIPDATE", "COMMITDATE", "RECEIPTDATE", "SHIPINSTRUCT", "SHIPMODE"],
    src_ldts="_LOAD_TIMESTAMP",
    src_source="_RECORD_SOURCE",
    source_model="stg_lineitem"
) }}
