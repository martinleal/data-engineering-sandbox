{{ config(materialized='incremental', schema='BDV_SALES') }}

{%- set yaml_metadata -%}
source_model: "hub_customer"
src_pk: "HK_CUSTOMER"
as_of_dates_table: "as_of_date"
satellites:
  sat_customer_account:
    ldts:
        ldts_col: _LOAD_TIMESTAMP
    pk:
        pk_col: HK_CUSTOMER
sat_customer_contact:
    ldts:
        ldts_col: _LOAD_TIMESTAMP
    pk:
        pk_col: HK_CUSTOMER
stage_tables_ldts:
  sat_customer_account:
    hk_col: HK_CUSTOMER
    ldts_col: _LOAD_TIMESTAMP
sat_customer_contact:
    hk_col: HK_CUSTOMER
    ldts_col: _LOAD_TIMESTAMP
src_ldts: "_LOAD_TIMESTAMP"
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ dbtvault.pit(source_model=metadata_dict['source_model'],
                 src_pk=metadata_dict['src_pk'],
                 as_of_dates_table=metadata_dict['as_of_dates_table'],
                 satellites=metadata_dict['satellites'],
                 stage_tables_ldts=metadata_dict['stage_tables_ldts'],
                 src_ldts=metadata_dict['src_ldts']) }}
