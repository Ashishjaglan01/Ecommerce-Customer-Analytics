
-- File: 03_customer_analysis.sql
-- Purpose: Understand customer behavior, spending, and repeat purchases


-- 1. One-time vs repeat customers
-- customer_unique_id represents the underlying customer identity.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers AS c
    JOIN public.orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customer_orders
GROUP BY 1
ORDER BY total_customers DESC;


-- 2. Top 10 customers by total recorded payment value
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spent,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers AS c
    JOIN public.orders AS o
        ON c.customer_id = o.customer_id
    JOIN public.payments AS p
        ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    total_orders,
    ROUND(total_spent::numeric, 2) AS total_spent
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 10;


-- 3. Average number of orders per unique customer
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers AS c
    JOIN public.orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers,
    SUM(total_orders) AS total_orders,
    ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_customer
FROM customer_orders;


-- 4. Customer purchase-frequency distribution
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers AS c
    JOIN public.orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    total_orders,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;
