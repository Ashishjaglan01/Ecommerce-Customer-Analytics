
-- File: 04_delivery_analysis.sql
-- Purpose: Analyze delivery performance and logistics issues


-- 1. Overall delivery performance
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN 'Missing delivery date'
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
            THEN 'On time or early'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM public.orders
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY total_orders DESC;


-- 2. Late-delivery rate by customer state
SELECT
    c.customer_state,
    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date IS NOT NULL
          AND o.order_estimated_delivery_date IS NOT NULL
    ) AS orders_with_delivery_dates,
    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date
              > o.order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date
                  > o.order_estimated_delivery_date
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE o.order_delivered_customer_date IS NOT NULL
                  AND o.order_estimated_delivery_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_delivery_percentage
FROM public.orders AS o
JOIN public.customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY late_delivery_percentage DESC;


-- 3. Average delivery time in days
SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS avg_delivery_days
FROM public.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL;


-- 4. Delivery performance by month
SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::date AS order_month,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              <= order_estimated_delivery_date
    ) AS on_time_or_early,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders
FROM public.orders
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 1;


-- 5. Orders with missing delivery timestamps
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM public.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
