DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS marketing_channels CASCADE;

CREATE TABLE marketing_channels (
    channel_id SERIAL PRIMARY KEY,
    channel_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20),
    birth_date DATE,
    city VARCHAR(100),
    registration_date DATE NOT NULL,
    channel_id INT REFERENCES marketing_channels(channel_id)
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL REFERENCES categories(category_id),
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    cost NUMERIC(10, 2) NOT NULL CHECK (cost >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(50) NOT NULL CHECK (
        order_status IN ('created', 'paid', 'shipped', 'delivered', 'cancelled', 'returned')
    )
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_percent NUMERIC(5, 2) NOT NULL DEFAULT 0 CHECK (
        discount_percent >= 0 AND discount_percent <= 100
    )
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_date TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL CHECK (
        payment_method IN ('card', 'cash', 'sbp', 'installment')
    ),
    payment_status VARCHAR(50) NOT NULL CHECK (
        payment_status IN ('pending', 'paid', 'failed', 'refunded')
    )
);

CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
    delivery_city VARCHAR(100) NOT NULL,
    delivery_status VARCHAR(50) NOT NULL CHECK (
        delivery_status IN ('not_started', 'in_progress', 'delivered', 'failed', 'returned')
    ),
    planned_delivery_date DATE,
    actual_delivery_date DATE
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date DATE NOT NULL
);