-- Project: Olist E-commerce Customer Analytics
-- Purpose: Validate imported data and investigate anomalies

-- 1. Check the total number of tables
SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- 2. Check order status distribution
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM public.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 3. Check duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM public.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. Check missing purchase timestamps
SELECT COUNT(*) AS missing_purchase_timestamps
FROM public.orders
WHERE order_purchase_timestamp IS NULL;

-- 5. Investigate late-period orders
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'canceled'
    ) AS canceled_orders
FROM public.orders
WHERE order_purchase_timestamp >= DATE '2018-08-01'
GROUP BY 1
ORDER BY 1;