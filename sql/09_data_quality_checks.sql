-- 09_data_quality_checks.sql
-- Data quality checks for ecommerce_analytics project


-- 1. Заказы без состава заказа
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;


-- 2. Заказы без оплаты
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;


-- 3. Заказы без доставки
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status
FROM orders o
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_id IS NULL;


-- 4. Товары с некорректной ценой или себестоимостью
SELECT
    product_id,
    product_name,
    price,
    cost
FROM products
WHERE price < 0
   OR cost < 0
   OR cost > price;


-- 5. Некорректные скидки
SELECT
    order_item_id,
    order_id,
    product_id,
    discount_percent
FROM order_items
WHERE discount_percent < 0
   OR discount_percent > 100;


-- 6. Доставки, где фактическая дата раньше даты заказа
SELECT
    d.delivery_id,
    d.order_id,
    o.order_date::DATE AS order_date,
    d.actual_delivery_date
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
WHERE d.actual_delivery_date IS NOT NULL
  AND d.actual_delivery_date < o.order_date::DATE;


-- 7. Доставленные заказы без успешной оплаты
SELECT
    o.order_id,
    o.order_status,
    p.payment_status
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND p.payment_status <> 'paid';


-- 8. Отзывы по заказам, которые не были доставлены или возвращены
SELECT
    r.review_id,
    r.order_id,
    o.order_status,
    r.rating,
    r.review_text
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status NOT IN ('delivered', 'returned');


-- 9. Клиенты без заказов
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.registration_date,
    c.city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- 10. Дублирующиеся названия товаров
SELECT
    product_name,
    COUNT(*) AS duplicates_count
FROM products
GROUP BY product_name
HAVING COUNT(*) > 1;


-- 11. Количество строк в основных таблицах
SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
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


-- 12. Проверка соответствия статуса заказа, оплаты и доставки
SELECT
    o.order_id,
    o.order_status,
    p.payment_status,
    d.delivery_status
FROM orders o
JOIN payments p ON o.order_id = p.order_id
JOIN deliveries d ON o.order_id = d.order_id
WHERE 
    (o.order_status = 'delivered' AND (p.payment_status <> 'paid' OR d.delivery_status <> 'delivered'))
    OR
    (o.order_status = 'returned' AND p.payment_status <> 'refunded')
    OR
    (o.order_status = 'cancelled' AND d.delivery_status <> 'not_started');