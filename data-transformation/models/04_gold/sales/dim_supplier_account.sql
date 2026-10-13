{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='SUPPLIER_KEY'
) }}


SELECT
    HK_SUPPLIER AS SUPPLIER_KEY,
    ACCOUNT_BALANCE_VL,
    ACCOUNT_STATUS_CD,
    _LOAD_TIMESTAMP AS _SOURCE_LOAD_TIMESTAMP
FROM {{ ref('bsat_supplier_account') }}
{% if is_incremental() %}
where _LOAD_TIMESTAMP > (
    select max(_LOAD_TIMESTAMP)
    from {{ this }}
)
{% endif %}
qualify row_number() over (
    partition by HK_SUPPLIER
    order by _LOAD_TIMESTAMP desc, HD_BDV_SUPPLIER_ACCOUNT desc
) = 1