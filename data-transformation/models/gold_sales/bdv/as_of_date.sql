{{ config(materialized='table', schema='BDV_SALES') }}

WITH date_spine AS (
    SELECT 
        DATEADD(day, seq4(), '2020-01-01'::DATE) AS AS_OF_DATE
    FROM TABLE(GENERATOR(ROWCOUNT => 365 * 10))
)

SELECT 
    AS_OF_DATE
FROM date_spine
WHERE AS_OF_DATE <= CURRENT_DATE()
