{{ config(materialized='incremental', schema='BDV_SALES') }}

WITH source_data AS (
    SELECT 
        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        TRIM(NAME) AS CUSTOMER_NAME,
        TRIM(ADDRESS) AS ADDRESS_TX,
        TRIM(PHONE) AS PHONE_NUMBER_TX
    FROM {{ ref('sat_customer_contact') }}
),

stage_bdv AS (
    SELECT
        HK_CUSTOMER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['CUSTOMER_NAME', 'ADDRESS_TX', 'PHONE_NUMBER_TX']) }} AS HD_BDV_CUSTOMER_CONTACT,
        CUSTOMER_NAME,
        ADDRESS_TX,
        PHONE_NUMBER_TX        
    FROM source_data
)

SELECT * FROM stage_bdv
