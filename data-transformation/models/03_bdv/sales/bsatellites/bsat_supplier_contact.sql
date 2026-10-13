
WITH source_data AS (
    SELECT 
        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        TRIM(NAME) AS SUPPLIER_NAME,
        TRIM(ADDRESS) AS ADDRESS_TX,
        TRIM(PHONE) AS PHONE_NUMBER_TX
    FROM {{ ref('sat_supplier_contact') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_SUPPLIER
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1
),

stage_bdv AS (
    SELECT
        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['SUPPLIER_NAME', 'ADDRESS_TX', 'PHONE_NUMBER_TX']) }} AS HD_BDV_SUPPLIER_CONTACT,
        SUPPLIER_NAME,
        ADDRESS_TX,
        PHONE_NUMBER_TX        
    FROM source_data
)

SELECT * FROM stage_bdv
