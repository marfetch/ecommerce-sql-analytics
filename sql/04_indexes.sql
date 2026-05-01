-- 03_indexes.sql
-- Indexes for ecommerce_analytics project

-- Индекс для быстрого поиска заказов по клиенту
CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

-- Индекс для анализа заказов по датам
CREATE INDEX idx_orders_order_date
ON orders(order_date);

-- Индекс для фильтрации заказов по статусу
CREATE INDEX idx_orders_status
ON orders(order_status);

-- Индекс для быстрого соединения order_items с заказами
CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

-- Индекс для анализа продаж по товарам
CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

-- Индекс для анализа клиентов по каналам привлечения
CREATE INDEX idx_customers_channel_id
ON customers(channel_id);

-- Индекс для анализа товаров по категориям
CREATE INDEX idx_products_category_id
ON products(category_id);

-- Индекс для анализа оплат по статусам
CREATE INDEX idx_payments_status
ON payments(payment_status);

-- Индекс для анализа доставок по статусам
CREATE INDEX idx_deliveries_status
ON deliveries(delivery_status);

-- Индекс для анализа отзывов по рейтингу
CREATE INDEX idx_reviews_rating
ON reviews(rating);