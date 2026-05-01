-- 02_insert_reference_data.sql
-- Reference data for ecommerce_analytics project

TRUNCATE TABLE
    reviews,
    deliveries,
    payments,
    order_items,
    orders,
    products,
    categories,
    customers,
    marketing_channels
RESTART IDENTITY CASCADE;

INSERT INTO marketing_channels (channel_name)
VALUES
    ('organic_search'),
    ('social_media'),
    ('context_ads'),
    ('email_marketing'),
    ('referral'),
    ('direct'),
    ('marketplace'),
    ('mobile_app');

INSERT INTO categories (category_name)
VALUES
    ('Electronics'),
    ('Home Appliances'),
    ('Clothing'),
    ('Shoes'),
    ('Beauty'),
    ('Sports'),
    ('Books'),
    ('Accessories'),
    ('Furniture'),
    ('Kids');