
WITH source_data AS (
    SELECT 
        HK_ORDER_LINE,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        CAST(QUANTITY AS NUMBER(38,2)) AS QUANTITY_VL,
        EXTENDEDPRICE AS GROSS_AMOUNT_VL,
        COALESCE(DISCOUNT, 0.00) AS DISCOUNT_PCT,
        COALESCE(TAX, 0.00) AS TAX_PCT,
        EXTENDEDPRICE * (1 - COALESCE(DISCOUNT, 0.00)) AS NET_REVENUE_AMT
    FROM {{ ref('sat_order_line_finance') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_ORDER_LINE
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1
),

stage_bdv AS (
    SELECT
        HK_ORDER_LINE,
        _LOAD_TIMESTAMP,
        _RECORD_SOURCE,
        {{ dbt_utils.generate_surrogate_key(['QUANTITY_VL', 'GROSS_AMOUNT_VL', 'DISCOUNT_PCT', 'TAX_PCT', 'NET_REVENUE_AMT']) }} AS HD_BDV_ORDER_LINE_FINANCE,
        QUANTITY_VL,
        GROSS_AMOUNT_VL,
        DISCOUNT_PCT,
        TAX_PCT,
        NET_REVENUE_AMT        
    FROM source_data
)

SELECT * FROM stage_bdv
