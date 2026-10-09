{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='PRODUCT_KEY'
) }}


select
    HK_PRODUCT as PRODUCT_KEY,
    PRODUCT_NAME,
    MANUFACTURER_NAME,
    BRAND_NAME,
    PRODUCT_TYPE_NAME,
    PRODUCT_SIZE_NUM,
    CONTAINER_TYPE_CD,
    RETAIL_PRICE_VL,
    IS_PREMIUM_PRODUCT,
    _LOAD_TIMESTAMP,
    _RECORD_SOURCE
from {{ ref('bsat_product') }}
{% if is_incremental() %}
where _LOAD_TIMESTAMP > (
    select max(_LOAD_TIMESTAMP)
    from {{ this }}
)
{% endif %}
qualify row_number() over (
    partition by HK_PRODUCT
    order by _LOAD_TIMESTAMP desc, HD_BDV_PRODUCT desc
) = 1