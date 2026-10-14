
-- File: 02_sales_analysis.sql
-- Purpose: Analyze sales, categories, payments, and monthly trends

-- 1. Overall sales performance
-- Payment totals include freight and other recorded charges.
WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM public.payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders_with_payment,
    ROUND(SUM(order_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(order_value)::numeric, 2) AS average_order_value
FROM order_payments;


-- 2. Top 10 product categories by product revenue
-- Product revenue excludes freight.
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS category_name,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::numeric, 2) AS product_revenue
FROM public.order_items AS oi
JOIN public.products AS p
    ON oi.product_id = p.product_id
LEFT JOIN public.category_translation AS ct
    ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY product_revenue DESC
LIMIT 10;


-- 3. Payment method analysis
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(payment_value)::numeric, 2) AS average_payment_value
FROM public.payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- 4. Monthly order volume and payment value
-- Payments are aggregated per order to avoid multiplying order counts.
WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM public.payments
    GROUP BY order_id
)
SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::date AS order_month,
    COUNT(*) AS orders_with_payment,
    ROUND(SUM(op.order_value)::numeric, 2) AS total_payment_value
FROM public.orders AS o
JOIN order_payments AS op
    ON o.order_id = op.order_id
GROUP BY 1
ORDER BY 1;


-- 5. Monthly order counts by status
-- Useful for examining incomplete or anomalous periods.
SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,
    order_status,
    COUNT(*) AS total_orders
FROM public.orders
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
