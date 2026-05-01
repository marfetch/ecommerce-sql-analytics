# Logical Data Model

## Назначение логической модели

Логическая модель описывает структуру базы данных на уровне таблиц, ключей и связей между сущностями.

В отличие от концептуальной модели, здесь уже указываются таблицы, первичные ключи, внешние ключи и типы связей.

## Таблицы и связи

### 1. `marketing_channels` → `customers`

**Связь:** 1 : N.

Один маркетинговый канал может привести много клиентов, но каждый клиент связан только с одним каналом привлечения.

marketing_channels.channel_id = customers.channel_id

### 2. `customers` → `orders`

**Связь:** 1 : N.

Один клиент может оформить много заказов. Каждый заказ принадлежит одному клиенту.

customers.customer_id = orders.customer_id

### 3. `categories` → `products`

**Связь:** 1 : N.

Одна категория может содержать много товаров. Каждый товар относится к одной категории.

categories.category_id = products.category_id

### 4. `orders` → `order_items`

**Связь:** 1 : N.

Один заказ может содержать несколько товарных позиций. Каждая позиция заказа относится к одному заказу.

orders.order_id = order_items.order_id

### 5. `products` → `order_items`

**Связь:** 1 : N.

Один товар может входить во множество заказов. Каждая позиция заказа относится к одному товару.

products.product_id = order_items.product_id

### 6. `orders` → `payments`

**Связь:** 1 : 1.

Один заказ имеет одну запись об оплате. Одна запись об оплате относится к одному заказу.

orders.order_id = payments.order_id

### 7. `orders` → `deliveries`

**Связь:** 1 : 1.

Один заказ имеет одну запись о доставке. Одна доставка относится к одному заказу.

orders.order_id = deliveries.order_id

### 8. `customers` → `reviews`

**Связь:** 1 : N.

Один клиент может оставить несколько отзывов.

customers.customer_id = reviews.customer_id

### 9. `products` → `reviews`

**Связь:** 1 : N.

Один товар может иметь несколько отзывов.

products.product_id = reviews.product_id

### 9. `orders` → `reviews`

**Связь:** 1 : N.

Один заказ может иметь несколько отзывов, если в заказе было несколько товаров.

orders.order_id = reviews.order_id
