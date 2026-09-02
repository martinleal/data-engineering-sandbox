{{ config(materialized='view', schema='BDV_SALES') }}

SELECT * 
FROM {{ ref('hub_nation') }}
