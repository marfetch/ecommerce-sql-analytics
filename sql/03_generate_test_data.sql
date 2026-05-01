-- 03_generate_test_data.sql
-- Synthetic data generation for ecommerce_analytics project
-- Generates products, customers, orders, order items, payments, deliveries and reviews.

-- 1. Products generation

INSERT INTO products (
    product_name,
    category_id,
    price,
    cost,
    is_active
)
SELECT
    product_prefix || ' ' || gs::TEXT AS product_name,
    category_id,
    price,
    ROUND(price * cost_share, 2) AS cost,
    TRUE AS is_active
FROM (
    SELECT
        gs,
        ((gs - 1) % 10) + 1 AS category_id,
        CASE ((gs - 1) % 10) + 1
            WHEN 1 THEN 'Electronics Item'
            WHEN 2 THEN 'Home Appliance'
            WHEN 3 THEN 'Clothing Item'
            WHEN 4 THEN 'Shoes Model'
            WHEN 5 THEN 'Beauty Product'
            WHEN 6 THEN 'Sports Product'
            WHEN 7 THEN 'Book'
            WHEN 8 THEN 'Accessory'
            WHEN 9 THEN 'Furniture Item'
            WHEN 10 THEN 'Kids Product'
        END AS product_prefix,
        CASE ((gs - 1) % 10) + 1
            WHEN 1 THEN ROUND((3000 + random() * 60000)::NUMERIC, 2)
            WHEN 2 THEN ROUND((2000 + random() * 50000)::NUMERIC, 2)
            WHEN 3 THEN ROUND((700 + random() * 8000)::NUMERIC, 2)
            WHEN 4 THEN ROUND((1500 + random() * 15000)::NUMERIC, 2)
            WHEN 5 THEN ROUND((500 + random() * 7000)::NUMERIC, 2)
            WHEN 6 THEN ROUND((800 + random() * 12000)::NUMERIC, 2)
            WHEN 7 THEN ROUND((300 + random() * 3000)::NUMERIC, 2)
            WHEN 8 THEN ROUND((400 + random() * 10000)::NUMERIC, 2)
            WHEN 9 THEN ROUND((5000 + random() * 80000)::NUMERIC, 2)
            WHEN 10 THEN ROUND((600 + random() * 15000)::NUMERIC, 2)
        END AS price,
        CASE ((gs - 1) % 10) + 1
            WHEN 1 THEN 0.62
            WHEN 2 THEN 0.66
            WHEN 3 THEN 0.45
            WHEN 4 THEN 0.52
            WHEN 5 THEN 0.40
            WHEN 6 THEN 0.50
            WHEN 7 THEN 0.35
            WHEN 8 THEN 0.42
            WHEN 9 THEN 0.68
            WHEN 10 THEN 0.48
        END AS cost_share
    FROM generate_series(1, 80) AS gs
) product_data;


-- 2. Customers generation

INSERT INTO customers (
    first_name,
    last_name,
    gender,
    birth_date,
    city,
    registration_date,
    channel_id
)
SELECT
    first_names[1 + floor(random() * array_length(first_names, 1))::INT] AS first_name,
    last_names[1 + floor(random() * array_length(last_names, 1))::INT] AS last_name,
    CASE 
        WHEN random() < 0.52 THEN 'female'
        ELSE 'male'
    END AS gender,
    DATE '1975-01-01' + floor(random() * 12000)::INT AS birth_date,
    cities[1 + floor(random() * array_length(cities, 1))::INT] AS city,
    DATE '2023-01-01' + floor(random() * 500)::INT AS registration_date,
    1 + floor(random() * 8)::INT AS channel_id
FROM generate_series(1, 700),
LATERAL (
    SELECT
        ARRAY[
            'Ivan', 'Pavel', 'Dmitry', 'Alexey', 'Nikita', 'Sergey', 'Mikhail', 'Andrey',
            'Anna', 'Maria', 'Elena', 'Olga', 'Sofia', 'Daria', 'Alina', 'Victoria'
        ] AS first_names,
        ARRAY[
            'Petrov', 'Ivanov', 'Sidorov', 'Smirnov', 'Kuznetsov', 'Popov', 'Volkov',
            'Fedorov', 'Mikhailov', 'Morozov', 'Novikov', 'Lebedev', 'Sokolov'
        ] AS last_names,
        ARRAY[
            'Moscow', 'Saint Petersburg', 'Kazan', 'Novosibirsk', 'Yekaterinburg',
            'Nizhny Novgorod', 'Samara', 'Rostov-on-Don', 'Krasnodar', 'Voronezh'
        ] AS cities
) arrays;


-- 3. Orders generation

INSERT INTO orders (
    customer_id,
    order_date,
    order_status
)
SELECT
    1 + floor(random() * 700)::INT AS customer_id,
    TIMESTAMP '2023-01-01 00:00:00'
        + (floor(random() * 610)::INT || ' days')::INTERVAL
        + (floor(random() * 24)::INT || ' hours')::INTERVAL
        + (floor(random() * 60)::INT || ' minutes')::INTERVAL AS order_date,
    CASE
        WHEN random() < 0.72 THEN 'delivered'
        WHEN random() < 0.82 THEN 'shipped'
        WHEN random() < 0.90 THEN 'cancelled'
        WHEN random() < 0.96 THEN 'returned'
        ELSE 'created'
    END AS order_status
FROM generate_series(1, 2500);


-- 4. Order items generation
-- Each order receives 1-4 products.

INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_percent
)
SELECT
    o.order_id,
    p.product_id,
    1 + floor(random() * 4)::INT AS quantity,
    p.price AS unit_price,
    CASE
        WHEN random() < 0.55 THEN 0
        WHEN random() < 0.75 THEN 5
        WHEN random() < 0.88 THEN 10
        WHEN random() < 0.96 THEN 15
        ELSE 20
    END AS discount_percent
FROM orders o
JOIN LATERAL (
    SELECT product_id, price
    FROM products
    ORDER BY random()
    LIMIT 1 + floor(random() * 4)::INT
) p ON TRUE;


-- 5. Payments generation

INSERT INTO payments (
    order_id,
    payment_date,
    payment_method,
    payment_status
)
SELECT
    o.order_id,
    CASE
        WHEN o.order_status IN ('cancelled', 'created') AND random() < 0.60 THEN NULL
        ELSE o.order_date + (floor(random() * 120)::INT || ' minutes')::INTERVAL
    END AS payment_date,
    payment_methods[1 + floor(random() * array_length(payment_methods, 1))::INT] AS payment_method,
    CASE
        WHEN o.order_status IN ('delivered', 'shipped') THEN 'paid'
        WHEN o.order_status = 'returned' THEN 'refunded'
        WHEN o.order_status = 'cancelled' THEN 
            CASE WHEN random() < 0.70 THEN 'failed' ELSE 'refunded' END
        ELSE 'pending'
    END AS payment_status
FROM orders o,
LATERAL (
    SELECT ARRAY['card', 'cash', 'sbp', 'installment'] AS payment_methods
) methods;


-- 6. Deliveries generation

INSERT INTO deliveries (
    order_id,
    delivery_city,
    delivery_status,
    planned_delivery_date,
    actual_delivery_date
)
SELECT
    o.order_id,
    c.city AS delivery_city,
    CASE
        WHEN o.order_status = 'delivered' THEN 'delivered'
        WHEN o.order_status = 'shipped' THEN 'in_progress'
        WHEN o.order_status = 'returned' THEN 'returned'
        WHEN o.order_status = 'cancelled' THEN 'not_started'
        ELSE 'not_started'
    END AS delivery_status,
    CASE
        WHEN o.order_status = 'cancelled' THEN NULL
        ELSE (o.order_date::DATE + (2 + floor(random() * 6)::INT))
    END AS planned_delivery_date,
    CASE
        WHEN o.order_status = 'delivered' THEN
            (o.order_date::DATE + (1 + floor(random() * 8)::INT))
        WHEN o.order_status = 'returned' THEN
            (o.order_date::DATE + (3 + floor(random() * 10)::INT))
        ELSE NULL
    END AS actual_delivery_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;


-- 7. Reviews generation
-- Reviews are generated only for part of delivered and returned orders.

INSERT INTO reviews (
    order_id,
    product_id,
    customer_id,
    rating,
    review_text,
    review_date
)
SELECT
    o.order_id,
    oi.product_id,
    o.customer_id,
    CASE
        WHEN o.order_status = 'returned' THEN 1 + floor(random() * 3)::INT
        WHEN random() < 0.12 THEN 1 + floor(random() * 3)::INT
        WHEN random() < 0.45 THEN 4
        ELSE 5
    END AS rating,
    CASE
        WHEN o.order_status = 'returned' THEN 'Customer returned the product.'
        WHEN random() < 0.20 THEN 'Delivery could be faster.'
        WHEN random() < 0.40 THEN 'Good value for money.'
        WHEN random() < 0.70 THEN 'Product quality is good.'
        ELSE 'Satisfied with the purchase.'
    END AS review_text,
    COALESCE(d.actual_delivery_date, o.order_date::DATE) + (1 + floor(random() * 7)::INT) AS review_date
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE o.order_status IN ('delivered', 'returned')
  AND random() < 0.35;


-- 8. Quick control totals

SELECT 'products' AS table_name, COUNT(*) AS rows_count FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
ORDER BY table_name;