-- depends_on: {{ ref('bsat_order_line_finance') }}
-- depends_on: {{ ref('bsat_order_line_logistics') }}
-- depends_on: {{ ref('bsat_order') }}
-- depends_on: {{ ref('brg_customer_order_line') }}

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='ORDER_LINE_KEY'
) }}

{% if is_incremental() %}
WITH changed_order_lines AS (

    -- Bridge changes: includes changes to relationships
    -- represented by the bridge's summary timestamp.
    SELECT b.HK_ORDER_LINE
    FROM {{ ref('brg_customer_order_line') }} b

    WHERE b._LOAD_TIMESTAMP > (
        SELECT COALESCE(
            MAX(_BRIDGE_LOAD_TIMESTAMP),
            '1900-01-01'::TIMESTAMP_LTZ
        )
        FROM {{ this }}
    )

    UNION ALL

    -- Finance satellite changes
    SELECT HK_ORDER_LINE
    FROM {{ ref('bsat_order_line_finance') }}
    WHERE _LOAD_TIMESTAMP > (
        SELECT COALESCE(
            MAX(_FINANCE_LOAD_TIMESTAMP),
            '1900-01-01'::TIMESTAMP_LTZ
        )
        FROM {{ this }}
    )

    UNION ALL

    -- Logistics satellite changes
    SELECT HK_ORDER_LINE
    FROM {{ ref('bsat_order_line_logistics') }}
    WHERE _LOAD_TIMESTAMP > (
        SELECT COALESCE(
            MAX(_LOGISTICS_LOAD_TIMESTAMP),
            '1900-01-01'::TIMESTAMP_LTZ
        )
        FROM {{ this }}
    )

    UNION ALL

    -- Order satellite changes: propagate each changed order
    -- to all order lines belonging to it.
    SELECT b.HK_ORDER_LINE
    FROM {{ ref('brg_customer_order_line') }} b
    INNER JOIN {{ ref('bsat_order') }} o
        ON b.HK_ORDER = o.HK_ORDER
    WHERE o._LOAD_TIMESTAMP > (
        SELECT COALESCE(
            MAX(_ORDER_LOAD_TIMESTAMP),
            '1900-01-01'::TIMESTAMP_LTZ
        )
        FROM {{ this }}
    )
)
{% endif %}
SELECT
    b.HK_ORDER_LINE AS ORDER_LINE_KEY,
    b.HK_ORDER AS ORDER_KEY,
    b.HK_CUSTOMER AS CUSTOMER_KEY,
    b.HK_CUSTOMER_REGION AS CUSTOMER_REGION_KEY,
    b.HK_CUSTOMER_NATION AS CUSTOMER_NATION_KEY,
    b.HK_PRODUCT AS PRODUCT_KEY,
    b.HK_SUPPLIER AS SUPPLIER_KEY,
    b.HK_SUPPLIER_REGION AS SUPPLIER_REGION_KEY,
    b.HK_SUPPLIER_NATION AS SUPPLIER_NATION_KEY,

    -- Order-level attributes
    o.ORDER_STATUS_CD,
    o.TOTAL_PRICE_VL,
    o.ORDER_DT,
    o.ORDER_PRIORITY_CD,
    o.CLERK_TX,
    o.SHIP_PRIORITY_CD,

    -- Date keys
    TO_NUMBER(TO_CHAR(o.ORDER_DT, 'YYYYMMDD')) AS ORDER_DATE_KEY,
    TO_NUMBER(TO_CHAR(l.SHIP_DT, 'YYYYMMDD')) AS SHIP_DATE_KEY,
    TO_NUMBER(TO_CHAR(l.COMMIT_DT, 'YYYYMMDD')) AS COMMIT_DATE_KEY,
    TO_NUMBER(TO_CHAR(l.RECEIPT_DT, 'YYYYMMDD')) AS RECEIPT_DATE_KEY,

    -- Line-level financial metrics
    f.QUANTITY_VL,
    f.GROSS_AMOUNT_VL,
    f.DISCOUNT_PCT,
    f.TAX_PCT,
    f.NET_REVENUE_AMT,

    -- Line-level logistics attributes
    l.RETURN_FLAG_CD,
    l.LINE_STATUS_CD,
    l.SHIP_INSTRUCTION_TX,
    l.SHIP_MODE_CD,
    l.IS_LATE_SHIPMENT_FL,

    -- Source-specific timestamps
    b._LOAD_TIMESTAMP AS _BRIDGE_LOAD_TIMESTAMP,
    f._LOAD_TIMESTAMP AS _FINANCE_LOAD_TIMESTAMP,
    l._LOAD_TIMESTAMP AS _LOGISTICS_LOAD_TIMESTAMP,
    o._LOAD_TIMESTAMP AS _ORDER_LOAD_TIMESTAMP,

    -- Latest source timestamp represented by this row
    GREATEST_IGNORE_NULLS(
        b._LOAD_TIMESTAMP,
        f._LOAD_TIMESTAMP,
        l._LOAD_TIMESTAMP,
        o._LOAD_TIMESTAMP
    ) AS _LOAD_TIMESTAMP

FROM {{ ref('brg_customer_order_line') }} b

LEFT JOIN {{ ref('bsat_order_line_finance') }} f
    ON b.HK_ORDER_LINE = f.HK_ORDER_LINE

LEFT JOIN {{ ref('bsat_order_line_logistics') }} l
    ON b.HK_ORDER_LINE = l.HK_ORDER_LINE

LEFT JOIN {{ ref('bsat_order') }} o
    ON b.HK_ORDER = o.HK_ORDER
{% if is_incremental() %}
WHERE EXISTS (
    SELECT 1
    FROM changed_order_lines c
    WHERE c.HK_ORDER_LINE = b.HK_ORDER_LINE
)
{% endif %}
