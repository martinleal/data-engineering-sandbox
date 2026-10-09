{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='CUSTOMER_ACCOUNT_KEY'
) }}

WITH source_history AS (

    SELECT
        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        HD_BDV_CUSTOMER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        MARKET_SEGMENT_NAME,
        IS_PREMIUM_CUSTOMER_FL,

        LAG(HD_BDV_CUSTOMER_ACCOUNT) OVER (
            PARTITION BY HK_CUSTOMER
            ORDER BY _LOAD_TIMESTAMP, HD_BDV_CUSTOMER_ACCOUNT
        ) AS PREVIOUS_HASHDIFF

    FROM {{ ref('bsat_customer_account') }}

),

actual_changes AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'HK_CUSTOMER',
            '_LOAD_TIMESTAMP',
            'HD_BDV_CUSTOMER_ACCOUNT'
        ]) }} AS CUSTOMER_ACCOUNT_KEY,

        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        HD_BDV_CUSTOMER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        MARKET_SEGMENT_NAME,
        IS_PREMIUM_CUSTOMER_FL

    FROM source_history

    WHERE PREVIOUS_HASHDIFF IS NULL
       OR HD_BDV_CUSTOMER_ACCOUNT <> PREVIOUS_HASHDIFF

),

{% if is_incremental() %}

new_entities AS (

    SELECT DISTINCT s.HK_CUSTOMER

    FROM actual_changes s

    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ this }} t
        WHERE t.CUSTOMER_ACCOUNT_KEY = s.CUSTOMER_ACCOUNT_KEY
    )

),

affected_history AS (

    SELECT s.*
    FROM actual_changes s
    INNER JOIN new_entities n
        ON s.HK_CUSTOMER = n.HK_CUSTOMER

)

{% else %}

affected_history AS (

    SELECT *
    FROM actual_changes

)

{% endif %},

versioned AS (

    SELECT
        CUSTOMER_ACCOUNT_KEY,
        HK_CUSTOMER,
        ACCOUNT_BALANCE_VL,
        MARKET_SEGMENT_NAME,
        IS_PREMIUM_CUSTOMER_FL,
        _RECORD_SOURCE,

        _LOAD_TIMESTAMP AS VALID_FROM,

        LEAD(_LOAD_TIMESTAMP) OVER (
            PARTITION BY HK_CUSTOMER
            ORDER BY _LOAD_TIMESTAMP, HD_BDV_CUSTOMER_ACCOUNT
        ) AS VALID_TO

    FROM affected_history

)

SELECT
    CUSTOMER_ACCOUNT_KEY,
    HK_CUSTOMER,
    ACCOUNT_BALANCE_VL,
    MARKET_SEGMENT_NAME,
    IS_PREMIUM_CUSTOMER_FL,
    _RECORD_SOURCE,
    VALID_FROM,
    VALID_TO,
    VALID_TO IS NULL AS IS_CURRENT

FROM versioned
