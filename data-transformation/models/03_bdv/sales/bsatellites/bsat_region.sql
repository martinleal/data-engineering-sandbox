
WITH source_data AS (
    SELECT 
        HK_REGION,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        UPPER(TRIM(NAME)) AS REGION_NAME
    FROM {{ ref('sat_region') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_REGION
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1
),

stage_bdv AS (
    SELECT
        HK_REGION,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['REGION_NAME']) }} AS HD_BDV_REGION,
        REGION_NAME        
    FROM source_data
)

SELECT * FROM stage_bdv
