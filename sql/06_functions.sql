-- 06_functions.sql
-- SQL functions for ecommerce_analytics project


-- 1. Функция расчета выручки по конкретному заказу
CREATE OR REPLACE FUNCTION get_order_revenue(p_order_id INT)
RETURNS NUMERIC(12, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_revenue NUMERIC(12, 2);
BEGIN
    SELECT 
        ROUND(
            COALESCE(SUM(
                quantity * unit_price * (1 - discount_percent / 100)
            ), 0),
            2
        )
    INTO v_revenue
    FROM order_items
    WHERE order_id = p_order_id;

    RETURN v_revenue;
END;
$$;


-- Проверка:
-- SELECT get_order_revenue(1);


-- 2. Функция расчета валовой прибыли по конкретному заказу
CREATE OR REPLACE FUNCTION get_order_gross_profit(p_order_id INT)
RETURNS NUMERIC(12, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_gross_profit NUMERIC(12, 2);
BEGIN
    SELECT
        ROUND(
            COALESCE(SUM(
                oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100)
                - oi.quantity * p.cost
            ), 0),
            2
        )
    INTO v_gross_profit
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE oi.order_id = p_order_id;

    RETURN v_gross_profit;
END;
$$;


-- Проверка:
-- SELECT get_order_gross_profit(1);


-- 3. Функция определения клиентского сегмента по числу заказов и выручке
CREATE OR REPLACE FUNCTION get_customer_segment(
    p_orders_count INT,
    p_total_revenue NUMERIC
)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE
        WHEN p_orders_count >= 5 AND p_total_revenue >= 100000 THEN 'VIP customer'
        WHEN p_orders_count >= 3 AND p_total_revenue >= 50000 THEN 'loyal customer'
        WHEN p_orders_count >= 2 THEN 'repeat customer'
        WHEN p_orders_count = 1 THEN 'one-time customer'
        ELSE 'inactive customer'
    END;
END;
$$;


-- Проверка:
-- SELECT get_customer_segment(5, 120000);


-- 4. Функция определения результата доставки
CREATE OR REPLACE FUNCTION get_delivery_result(
    p_planned_date DATE,
    p_actual_date DATE
)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE
        WHEN p_planned_date IS NULL THEN 'no_plan'
        WHEN p_actual_date IS NULL THEN 'not_completed'
        WHEN p_actual_date <= p_planned_date THEN 'on_time'
        ELSE 'late'
    END;
END;
$$;


-- Проверка:
-- SELECT get_delivery_result('2024-01-10', '2024-01-12');