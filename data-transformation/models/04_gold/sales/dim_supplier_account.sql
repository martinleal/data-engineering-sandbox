{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='SUPPLIER_ACCOUNT_KEY'
) }}

WITH source_history AS (

    SELECT
        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        HD_BDV_SUPPLIER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        ACCOUNT_STATUS_CD,

        LAG(HD_BDV_SUPPLIER_ACCOUNT) OVER (
            PARTITION BY HK_SUPPLIER
            ORDER BY _LOAD_TIMESTAMP, HD_BDV_SUPPLIER_ACCOUNT
        ) AS PREVIOUS_HASHDIFF

    FROM {{ ref('bsat_supplier_account') }}

),

actual_changes AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'HK_SUPPLIER',
            '_LOAD_TIMESTAMP',
            'HD_BDV_SUPPLIER_ACCOUNT'
        ]) }} AS SUPPLIER_ACCOUNT_KEY,

        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        HD_BDV_SUPPLIER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        ACCOUNT_STATUS_CD

    FROM source_history

    WHERE PREVIOUS_HASHDIFF IS NULL
       OR HD_BDV_SUPPLIER_ACCOUNT <> PREVIOUS_HASHDIFF

),

{% if is_incremental() %}

new_entities AS (

    SELECT DISTINCT s.HK_SUPPLIER

    FROM actual_changes s

    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ this }} t
        WHERE t.SUPPLIER_ACCOUNT_KEY = s.SUPPLIER_ACCOUNT_KEY
    )

),

affected_history AS (

    SELECT s.*
    FROM actual_changes s
    INNER JOIN new_entities n
        ON s.HK_SUPPLIER = n.HK_SUPPLIER

)

{% else %}

affected_history AS (

    SELECT *
    FROM actual_changes

)

{% endif %},

versioned AS (

    SELECT
        SUPPLIER_ACCOUNT_KEY,
        HK_SUPPLIER,
        ACCOUNT_BALANCE_VL,
        ACCOUNT_STATUS_CD,
        _RECORD_SOURCE,

        _LOAD_TIMESTAMP AS VALID_FROM,

        LEAD(_LOAD_TIMESTAMP) OVER (
            PARTITION BY HK_SUPPLIER
            ORDER BY _LOAD_TIMESTAMP, HD_BDV_SUPPLIER_ACCOUNT
        ) AS VALID_TO

    FROM affected_history

)

SELECT
    SUPPLIER_ACCOUNT_KEY,
    HK_SUPPLIER,
    ACCOUNT_BALANCE_VL,
    ACCOUNT_STATUS_CD,
    _RECORD_SOURCE,
    VALID_FROM,
    VALID_TO,
    VALID_TO IS NULL AS IS_CURRENT

FROM versioned
