-- 04_views.sql
-- Views for ecommerce_analytics project

DROP VIEW IF EXISTS v_order_details;
DROP VIEW IF EXISTS v_customer_orders;
DROP VIEW IF EXISTS v_product_sales;
DROP VIEW IF EXISTS v_delivery_performance;

CREATE VIEW v_order_details AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city AS customer_city,
    mc.channel_name,
    p.product_id,
    p.product_name,
    cat.category_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_percent,
    ROUND(
        oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100),
        2
    ) AS revenue,
    ROUND(
        oi.quantity * p.cost,
        2
    ) AS total_cost,
    ROUND(
        oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100) - oi.quantity * p.cost,
        2
    ) AS gross_profit,
    pay.payment_method,
    pay.payment_status,
    d.delivery_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN marketing_channels mc ON c.channel_id = mc.channel_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN payments pay ON o.order_id = pay.order_id
LEFT JOIN deliveries d ON o.order_id = d.order_id;


CREATE VIEW v_customer_orders AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    mc.channel_name,
    c.registration_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE 
        WHEN o.order_status = 'delivered' THEN o.order_id 
    END) AS delivered_orders,
    ROUND(
        COALESCE(SUM(
            CASE 
                WHEN o.order_status = 'delivered'
                THEN oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100)
                ELSE 0
            END
        ), 0),
        2
    ) AS total_revenue
FROM customers c
LEFT JOIN marketing_channels mc ON c.channel_id = mc.channel_id
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 
    c.customer_id,
    customer_name,
    c.city,
    mc.channel_name,
    c.registration_date;


CREATE VIEW v_product_sales AS
SELECT
    p.product_id,
    p.product_name,
    cat.category_name,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100)),
        2
    ) AS revenue,
    ROUND(
        SUM(oi.quantity * p.cost),
        2
    ) AS total_cost,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100) - oi.quantity * p.cost),
        2
    ) AS gross_profit
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY 
    p.product_id,
    p.product_name,
    cat.category_name;


CREATE VIEW v_delivery_performance AS
SELECT
    d.delivery_id,
    d.order_id,
    d.delivery_city,
    d.delivery_status,
    d.planned_delivery_date,
    d.actual_delivery_date,
    CASE
        WHEN d.actual_delivery_date IS NULL OR d.planned_delivery_date IS NULL THEN NULL
        ELSE d.actual_delivery_date - d.planned_delivery_date
    END AS delay_days,
    CASE
        WHEN d.actual_delivery_date IS NULL THEN 'not_completed'
        WHEN d.actual_delivery_date <= d.planned_delivery_date THEN 'on_time'
        ELSE 'late'
    END AS delivery_result
FROM deliveries d;