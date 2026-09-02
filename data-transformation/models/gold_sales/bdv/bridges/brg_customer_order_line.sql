{{ config(materialized='table', schema='BDV_SALES') }}

SELECT
    lnk_olps.HK_ORDER_LINE,
    lnk_olps.HK_ORDER,
    lnk_oc.HK_CUSTOMER,
    lnk_olps.HK_PRODUCT,
    lnk_olps.HK_SUPPLIER,
    lnk_cn.HK_NATION AS HK_CUSTOMER_NATION,
    lnk_nr_cust.HK_REGION AS HK_CUSTOMER_REGION,
    lnk_sn.HK_NATION AS HK_SUPPLIER_NATION,
    lnk_nr_supp.HK_REGION AS HK_SUPPLIER_REGION
FROM {{ ref('lnk_order_line_product_supplier') }} lnk_olps
LEFT JOIN {{ ref('lnk_order_customer') }} lnk_oc
    ON lnk_olps.HK_ORDER = lnk_oc.HK_ORDER
LEFT JOIN {{ ref('lnk_customer_nation') }} lnk_cn
    ON lnk_oc.HK_CUSTOMER = lnk_cn.HK_CUSTOMER
LEFT JOIN {{ ref('lnk_nation_region') }} lnk_nr_cust
    ON lnk_cn.HK_NATION = lnk_nr_cust.HK_NATION
LEFT JOIN {{ ref('lnk_supplier_nation') }} lnk_sn
    ON lnk_olps.HK_SUPPLIER = lnk_sn.HK_SUPPLIER
LEFT JOIN {{ ref('lnk_nation_region') }} lnk_nr_supp
    ON lnk_sn.HK_NATION = lnk_nr_supp.HK_NATION
