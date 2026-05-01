-- 08_analytics_queries.sql
-- Analytical SQL queries for ecommerce_analytics project


-- 1. Общая выручка, прибыль и количество заказов
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(gross_profit) / NULLIF(SUM(revenue), 0) * 100, 2) AS gross_margin_percent
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid';


-- 2. Выручка по месяцам
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- 3. Средний чек по месяцам
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- 4. Топ товаров по выручке
SELECT
    product_name,
    category_name,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY product_name, category_name
ORDER BY revenue DESC
LIMIT 10;


-- 5. Выручка по категориям
SELECT
    category_name,
    COUNT(DISTINCT order_id) AS orders_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit,
    ROUND(SUM(gross_profit) / NULLIF(SUM(revenue), 0) * 100, 2) AS gross_margin_percent
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY category_name
ORDER BY revenue DESC;


-- 6. Эффективность каналов привлечения
SELECT
    channel_name,
    COUNT(DISTINCT customer_id) AS customers_count,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_customer
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY channel_name
ORDER BY revenue DESC;


-- 7. Повторные покупки клиентов
WITH customer_orders AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS orders_count,
        ROUND(SUM(revenue), 2) AS total_revenue
    FROM v_order_details
    WHERE order_status = 'delivered'
      AND payment_status = 'paid'
    GROUP BY customer_id, customer_name
)
SELECT
    customer_id,
    customer_name,
    orders_count,
    total_revenue,
    CASE
        WHEN orders_count = 1 THEN 'one-time customer'
        WHEN orders_count BETWEEN 2 AND 3 THEN 'repeat customer'
        ELSE 'loyal customer'
    END AS customer_segment
FROM customer_orders
ORDER BY total_revenue DESC;


-- 8. RFM-сегментация клиентов
WITH analysis_date AS (
    SELECT MAX(order_date)::DATE AS dt
    FROM orders
),
rfm AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        MAX(o.order_date)::DATE AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100)
        ), 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
      AND p.payment_status = 'paid'
    GROUP BY c.customer_id, customer_name
),
rfm_scores AS (
    SELECT
        r.*,
        a.dt - r.last_order_date AS recency_days,
        NTILE(3) OVER (ORDER BY a.dt - r.last_order_date DESC) AS recency_score,
        NTILE(3) OVER (ORDER BY r.frequency ASC) AS frequency_score,
        NTILE(3) OVER (ORDER BY r.monetary ASC) AS monetary_score
    FROM rfm r
    CROSS JOIN analysis_date a
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score AS rfm_total_score,
    CASE
        WHEN recency_score + frequency_score + monetary_score >= 8 THEN 'high value'
        WHEN recency_score + frequency_score + monetary_score BETWEEN 5 AND 7 THEN 'medium value'
        ELSE 'low value'
    END AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total_score DESC, monetary DESC;


-- 9. ABC-анализ товаров по выручке
WITH product_revenue AS (
    SELECT
        product_id,
        product_name,
        category_name,
        ROUND(SUM(revenue), 2) AS revenue
    FROM v_order_details
    WHERE order_status = 'delivered'
      AND payment_status = 'paid'
    GROUP BY product_id, product_name, category_name
),
abc AS (
    SELECT
        *,
        ROUND(
            revenue / SUM(revenue) OVER () * 100,
            2
        ) AS revenue_share_percent,
        ROUND(
            SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER () * 100,
            2
        ) AS cumulative_revenue_share_percent
    FROM product_revenue
)
SELECT
    product_id,
    product_name,
    category_name,
    revenue,
    revenue_share_percent,
    cumulative_revenue_share_percent,
    CASE
        WHEN cumulative_revenue_share_percent <= 80 THEN 'A'
        WHEN cumulative_revenue_share_percent <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_group
FROM abc
ORDER BY revenue DESC;


-- 10. Анализ доставок: вовремя / с задержкой
SELECT
    delivery_result,
    COUNT(*) AS deliveries_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS share_percent
FROM v_delivery_performance
GROUP BY delivery_result
ORDER BY deliveries_count DESC;


-- 11. Средний рейтинг товаров
SELECT
    p.product_name,
    c.category_name,
    COUNT(r.review_id) AS reviews_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_name, c.category_name
HAVING COUNT(r.review_id) > 0
ORDER BY avg_rating DESC, reviews_count DESC;


-- 12. Корреляция между скидкой и количеством проданных единиц
SELECT
    CORR(discount_percent, quantity) AS discount_quantity_corr
FROM order_items;


-- 13. Заказы с отрицательным клиентским опытом
SELECT
    r.review_id,
    r.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    r.rating,
    r.review_text,
    d.delivery_status,
    d.planned_delivery_date,
    d.actual_delivery_date
FROM reviews r
JOIN customers c ON r.customer_id = c.customer_id
JOIN products p ON r.product_id = p.product_id
LEFT JOIN deliveries d ON r.order_id = d.order_id
WHERE r.rating <= 3
ORDER BY r.rating ASC, r.review_date DESC;


-- 14. Динамика выручки с накопительным итогом
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    ROUND(SUM(revenue), 2) AS monthly_revenue,
    ROUND(
        SUM(SUM(revenue)) OVER (
            ORDER BY DATE_TRUNC('month', order_date)
        ),
        2
    ) AS cumulative_revenue
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- 15. Рейтинг городов по выручке
SELECT
    customer_city,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(DISTINCT customer_id) AS customers_count,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS revenue_per_customer
FROM v_order_details
WHERE order_status = 'delivered'
  AND payment_status = 'paid'
GROUP BY customer_city
ORDER BY revenue DESC;
