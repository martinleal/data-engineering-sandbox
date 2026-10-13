{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='CUSTOMER_KEY'
) }}


SELECT
    HK_CUSTOMER AS CUSTOMER_KEY,
    ACCOUNT_BALANCE_VL,
    MARKET_SEGMENT_NAME,
    IS_PREMIUM_CUSTOMER_FL,
    _LOAD_TIMESTAMP AS _SOURCE_LOAD_TIMESTAMP
FROM {{ ref('bsat_customer_account') }}
{% if is_incremental() %}
where _LOAD_TIMESTAMP > (
    select max(_LOAD_TIMESTAMP)
    from {{ this }}
)
{% endif %}
qualify row_number() over (
    partition by HK_CUSTOMER
    order by _LOAD_TIMESTAMP desc, HD_BDV_CUSTOMER_ACCOUNT desc
) = 1