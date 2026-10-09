
WITH source_data AS (
    SELECT 
        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        CAST(ACCTBAL AS NUMBER(38,2)) AS ACCOUNT_BALANCE_VL,
        CASE WHEN ACCTBAL < 0 THEN 'OVERDRAWN' WHEN ACCTBAL = 0 THEN 'ZERO' ELSE 'GOOD_STANDING' END AS ACCOUNT_STATUS_CD
    FROM {{ ref('sat_supplier_account') }}
),

stage_bdv AS (
    SELECT
        HK_SUPPLIER,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['ACCOUNT_BALANCE_VL', 'ACCOUNT_STATUS_CD']) }} AS HD_BDV_SUPPLIER_ACCOUNT,
        ACCOUNT_BALANCE_VL,
        ACCOUNT_STATUS_CD        
    FROM source_data
)

SELECT * FROM stage_bdv
