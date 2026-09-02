{{ config(materialized='view', schema='BDV_SALES') }}

SELECT * 
FROM {{ ref('lnk_product_supplier') }}
