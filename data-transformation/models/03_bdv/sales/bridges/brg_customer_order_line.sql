WITH lnk_olps AS (

    SELECT *
    FROM {{ ref('lnk_order_line_product_supplier') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_ORDER_LINE
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1

),

lnk_oc AS (

    SELECT *
    FROM {{ ref('lnk_order_customer') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_ORDER
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1

),

lnk_cn AS (

    SELECT *
    FROM {{ ref('lnk_customer_nation') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_CUSTOMER
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1

),

lnk_nr AS (

    SELECT *
    FROM {{ ref('lnk_nation_region') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_NATION
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1

),

lnk_sn AS (

    SELECT *
    FROM {{ ref('lnk_supplier_nation') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HK_SUPPLIER
        ORDER BY _LOAD_TIMESTAMP DESC
    ) = 1

)

SELECT
    lnk_olps.HK_ORDER_LINE,
    lnk_olps.HK_ORDER,
    lnk_oc.HK_CUSTOMER,
    lnk_olps.HK_PRODUCT,
    lnk_olps.HK_SUPPLIER,
    lnk_cn.HK_NATION AS HK_CUSTOMER_NATION,
    lnk_nr_cust.HK_REGION AS HK_CUSTOMER_REGION,
    lnk_sn.HK_NATION AS HK_SUPPLIER_NATION,
    lnk_nr_supp.HK_REGION AS HK_SUPPLIER_REGION,

    GREATEST_IGNORE_NULLS(
        lnk_olps._LOAD_TIMESTAMP,
        lnk_oc._LOAD_TIMESTAMP,
        lnk_cn._LOAD_TIMESTAMP,
        lnk_nr_cust._LOAD_TIMESTAMP,
        lnk_sn._LOAD_TIMESTAMP,
        lnk_nr_supp._LOAD_TIMESTAMP
    ) AS _LOAD_TIMESTAMP
FROM lnk_olps

LEFT JOIN lnk_oc
    ON lnk_olps.HK_ORDER = lnk_oc.HK_ORDER

LEFT JOIN lnk_cn
    ON lnk_oc.HK_CUSTOMER = lnk_cn.HK_CUSTOMER

LEFT JOIN lnk_nr AS lnk_nr_cust
    ON lnk_cn.HK_NATION = lnk_nr_cust.HK_NATION

LEFT JOIN lnk_sn
    ON lnk_olps.HK_SUPPLIER = lnk_sn.HK_SUPPLIER

LEFT JOIN lnk_nr AS lnk_nr_supp
    ON lnk_sn.HK_NATION = lnk_nr_supp.HK_NATION