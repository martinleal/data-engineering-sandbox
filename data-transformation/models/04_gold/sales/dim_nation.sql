{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='NATION_KEY'
) }}


SELECT
    HK_NATION AS NATION_KEY,
    NATION_NAME,
    _LOAD_TIMESTAMP
FROM {{ ref('bsat_nation') }}
{% if is_incremental() %}
where _LOAD_TIMESTAMP > (
    select max(_LOAD_TIMESTAMP)
    from {{ this }}
)
{% endif %}
qualify row_number() over (
    partition by HK_NATION 
    order by _LOAD_TIMESTAMP desc, HD_BDV_NATION desc
) = 1