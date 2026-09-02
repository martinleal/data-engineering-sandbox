{{ config(materialized='incremental', schema='BDV_SALES') }}

WITH source_data AS (
    SELECT 
        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        CAST(ACCTBAL AS NUMBER(38,2)) AS ACCOUNT_BALANCE_VL,
        UPPER(TRIM(MKTSEGMENT)) AS MARKET_SEGMENT_NAME,
        CAST(CASE WHEN ACCTBAL > 5000 THEN 1 ELSE 0 END AS BOOLEAN) AS IS_PREMIUM_CUSTOMER_FL
    FROM {{ ref('sat_customer_account') }}
),

stage_bdv AS (
    SELECT
        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['ACCOUNT_BALANCE_VL', 'MARKET_SEGMENT_NAME', 'IS_PREMIUM_CUSTOMER_FL']) }} AS HD_BDV_CUSTOMER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        MARKET_SEGMENT_NAME,
        IS_PREMIUM_CUSTOMER_FL        
    FROM source_data
)

SELECT * FROM stage_bdv
