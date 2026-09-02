{{ config(materialized='view', schema='BDV_SALES') }}

SELECT * 
FROM {{ ref('lnk_order_customer') }}
