

{% set yaml_metadata %}
source_model:
  TPCH_SF1: "PART"

derived_columns:
  _LOAD_TIMESTAMP: "_LOAD_TIMESTAMP"
  _RECORD_SOURCE: "_RECORD_SOURCE"
  ID_PRODUCT: "P_PARTKEY"
  NAME: "P_NAME"
  MFGR: "P_MFGR"
  BRAND: "P_BRAND"
  TYPE: "P_TYPE"
  SIZE: "P_SIZE"
  CONTAINER: "P_CONTAINER"
  RETAILPRICE: "P_RETAILPRICE"
  COMMENT: "P_COMMENT"

hashed_columns:
  HK_PRODUCT: "ID_PRODUCT"
  HD_PRODUCT:
    is_hashdiff: true
    columns:
      - "NAME"
      - "MFGR"
      - "BRAND"
      - "TYPE"
      - "SIZE"
      - "CONTAINER"
      - "RETAILPRICE"
      - "COMMENT"
{% endset %}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.stage(
    source_model=metadata_dict['source_model'],
    derived_columns=metadata_dict['derived_columns'],
    hashed_columns=metadata_dict['hashed_columns']
) }}
