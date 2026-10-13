{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='REGION_KEY'
) }}


SELECT
    HK_REGION AS REGION_KEY,
    REGION_NAME,
    _LOAD_TIMESTAMP AS _SOURCE_LOAD_TIMESTAMP
FROM {{ ref('bsat_region') }}
{% if is_incremental() %}
where _LOAD_TIMESTAMP > (
    select max(_LOAD_TIMESTAMP)
    from {{ this }}
)
{% endif %}
qualify row_number() over (
    partition by HK_REGION
    order by _LOAD_TIMESTAMP desc, HD_BDV_REGION desc
) = 1