-- 07_procedures.sql
-- Stored procedures for ecommerce_analytics project


-- 1. Процедура обновления статуса заказа
CREATE OR REPLACE PROCEDURE update_order_status(
    p_order_id INT,
    p_new_status VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_new_status NOT IN ('created', 'paid', 'shipped', 'delivered', 'cancelled', 'returned') THEN
        RAISE EXCEPTION 'Invalid order status: %', p_new_status;
    END IF;

    UPDATE orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order with id % was not found', p_order_id;
    END IF;
END;
$$;


-- Проверка:
-- CALL update_order_status(1, 'delivered');


-- 2. Процедура обновления статуса оплаты
CREATE OR REPLACE PROCEDURE update_payment_status(
    p_order_id INT,
    p_new_payment_status VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_new_payment_status NOT IN ('pending', 'paid', 'failed', 'refunded') THEN
        RAISE EXCEPTION 'Invalid payment status: %', p_new_payment_status;
    END IF;

    UPDATE payments
    SET 
        payment_status = p_new_payment_status,
        payment_date = CASE
            WHEN p_new_payment_status = 'paid' AND payment_date IS NULL THEN CURRENT_TIMESTAMP
            ELSE payment_date
        END
    WHERE order_id = p_order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment for order id % was not found', p_order_id;
    END IF;
END;
$$;


-- Проверка:
-- CALL update_payment_status(1, 'paid');


-- 3. Процедура деактивации товара
CREATE OR REPLACE PROCEDURE deactivate_product(
    p_product_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET is_active = FALSE
    WHERE product_id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product with id % was not found', p_product_id;
    END IF;
END;
$$;


-- Проверка:
-- CALL deactivate_product(1);


-- 4. Процедура создания простого заказа из одного товара
CREATE OR REPLACE PROCEDURE create_single_product_order(
    p_customer_id INT,
    p_product_id INT,
    p_quantity INT,
    p_discount_percent NUMERIC DEFAULT 0
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
    v_product_price NUMERIC(10, 2);
    v_customer_city VARCHAR(100);
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than 0';
    END IF;

    IF p_discount_percent < 0 OR p_discount_percent > 100 THEN
        RAISE EXCEPTION 'Discount percent must be between 0 and 100';
    END IF;

    SELECT price
    INTO v_product_price
    FROM products
    WHERE product_id = p_product_id
      AND is_active = TRUE;

    IF v_product_price IS NULL THEN
        RAISE EXCEPTION 'Active product with id % was not found', p_product_id;
    END IF;

    SELECT city
    INTO v_customer_city
    FROM customers
    WHERE customer_id = p_customer_id;

    IF v_customer_city IS NULL THEN
        RAISE EXCEPTION 'Customer with id % was not found', p_customer_id;
    END IF;

    INSERT INTO orders (
        customer_id,
        order_date,
        order_status
    )
    VALUES (
        p_customer_id,
        CURRENT_TIMESTAMP,
        'created'
    )
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_items (
        order_id,
        product_id,
        quantity,
        unit_price,
        discount_percent
    )
    VALUES (
        v_order_id,
        p_product_id,
        p_quantity,
        v_product_price,
        p_discount_percent
    );

    INSERT INTO payments (
        order_id,
        payment_date,
        payment_method,
        payment_status
    )
    VALUES (
        v_order_id,
        NULL,
        'card',
        'pending'
    );

    INSERT INTO deliveries (
        order_id,
        delivery_city,
        delivery_status,
        planned_delivery_date,
        actual_delivery_date
    )
    VALUES (
        v_order_id,
        v_customer_city,
        'not_started',
        CURRENT_DATE + INTERVAL '3 days',
        NULL
    );
END;
$$;


-- Проверка:
-- CALL create_single_product_order(1, 2, 1, 10);