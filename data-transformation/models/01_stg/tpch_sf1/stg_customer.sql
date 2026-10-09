

{% set yaml_metadata %}
source_model:
  TPCH_SF1: "CUSTOMER"

derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_CUSTOMER: "C_CUSTKEY"
  ID_NATION: "C_NATIONKEY"
  NAME: "C_NAME"
  ADDRESS: "C_ADDRESS"
  PHONE: "C_PHONE"
  COMMENT: "C_COMMENT"
  ACCTBAL: "C_ACCTBAL"
  MKTSEGMENT: "C_MKTSEGMENT"

hashed_columns:
  HK_CUSTOMER: "ID_CUSTOMER"
  HK_NATION: "ID_NATION"
  HK_LNK_CUSTOMER_NATION:
    - "HK_CUSTOMER"
    - "HK_NATION"
  HD_CUSTOMER_CONTACT:
    is_hashdiff: true
    columns:
      - "NAME"
      - "ADDRESS"
      - "PHONE"
      - "COMMENT"
  HD_CUSTOMER_ACCOUNT:
    is_hashdiff: true
    columns:
      - "ACCTBAL"
      - "MKTSEGMENT"
{% endset %}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(
    source_model=metadata_dict['source_model'],
    derived_columns=metadata_dict['derived_columns'],
    hashed_columns=metadata_dict['hashed_columns']
) }}
