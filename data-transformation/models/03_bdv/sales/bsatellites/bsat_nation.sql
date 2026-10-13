
WITH source_data AS (
    SELECT 
        HK_NATION,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        UPPER(TRIM(NAME)) AS NATION_NAME
    FROM {{ ref('sat_nation') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_NATION
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1
),

stage_bdv AS (
    SELECT
        HK_NATION,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['NATION_NAME']) }} AS HD_BDV_NATION,
        NATION_NAME        
    FROM source_data
)

SELECT * FROM stage_bdv
