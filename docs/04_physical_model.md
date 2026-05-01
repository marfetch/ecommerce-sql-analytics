# Физическая модель данных

## Назначение физической модели

Физическая модель описывает реализацию логической модели в PostgreSQL: таблицы, поля, типы данных, первичные и внешние ключи, ограничения, индексы, представления, функции и процедуры.

## Выбор типов данных

- `SERIAL` используется для surrogate key идентификаторов.
- `VARCHAR` используется для коротких текстовых атрибутов и статусов.
- `TEXT` используется для свободного текста отзыва.
- `DATE` используется для календарных дат без времени.
- `TIMESTAMP` используется для событий, где важно время.
- `NUMERIC(10, 2)` используется для денежных показателей, чтобы избежать ошибок округления `FLOAT`.
- `BOOLEAN` используется для признака активности товара.
- `INT` используется для идентификаторов, количества и рейтинга.

## Таблицы

### `marketing_channels`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `channel_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор канала |
| `channel_name` | `VARCHAR(100)` | `NOT NULL`, `UNIQUE` | Название канала |

### `customers`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `customer_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор клиента |
| `first_name` | `VARCHAR(100)` | `NOT NULL` | Имя |
| `last_name` | `VARCHAR(100)` | `NOT NULL` | Фамилия |
| `gender` | `VARCHAR(20)` |  | Пол |
| `birth_date` | `DATE` |  | Дата рождения |
| `city` | `VARCHAR(100)` |  | Город клиента |
| `registration_date` | `DATE` | `NOT NULL` | Дата регистрации |
| `channel_id` | `INT` | `FOREIGN KEY` | Канал привлечения |

### `categories`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `category_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор категории |
| `category_name` | `VARCHAR(100)` | `NOT NULL`, `UNIQUE` | Название категории |

### `products`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `product_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор товара |
| `product_name` | `VARCHAR(150)` | `NOT NULL` | Название товара |
| `category_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | Категория |
| `price` | `NUMERIC(10, 2)` | `NOT NULL`, `CHECK (price >= 0)` | Текущая цена |
| `cost` | `NUMERIC(10, 2)` | `NOT NULL`, `CHECK (cost >= 0)` | Себестоимость |
| `is_active` | `BOOLEAN` | `NOT NULL`, `DEFAULT TRUE` | Активность товара |

### `orders`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `order_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор заказа |
| `customer_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | Клиент |
| `order_date` | `TIMESTAMP` | `NOT NULL` | Дата и время заказа |
| `order_status` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | Статус заказа |

Допустимые статусы: `created`, `paid`, `shipped`, `delivered`, `cancelled`, `returned`.

### `order_items`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `order_item_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор позиции |
| `order_id` | `INT` | `NOT NULL`, `FOREIGN KEY`, `ON DELETE CASCADE` | Заказ |
| `product_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | Товар |
| `quantity` | `INT` | `NOT NULL`, `CHECK (quantity > 0)` | Количество |
| `unit_price` | `NUMERIC(10, 2)` | `NOT NULL`, `CHECK (unit_price >= 0)` | Цена на момент заказа |
| `discount_percent` | `NUMERIC(5, 2)` | `NOT NULL`, `DEFAULT 0`, `CHECK` | Скидка в процентах |

### `payments`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `payment_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор оплаты |
| `order_id` | `INT` | `NOT NULL`, `UNIQUE`, `FOREIGN KEY`, `ON DELETE CASCADE` | Заказ |
| `payment_date` | `TIMESTAMP` |  | Дата и время оплаты |
| `payment_method` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | Метод оплаты |
| `payment_status` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | Статус оплаты |

Методы оплаты: `card`, `cash`, `sbp`, `installment`. Статусы оплаты: `pending`, `paid`, `failed`, `refunded`.

### `deliveries`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `delivery_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор доставки |
| `order_id` | `INT` | `NOT NULL`, `UNIQUE`, `FOREIGN KEY`, `ON DELETE CASCADE` | Заказ |
| `delivery_city` | `VARCHAR(100)` | `NOT NULL` | Город доставки |
| `delivery_status` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | Статус доставки |
| `planned_delivery_date` | `DATE` |  | Плановая дата |
| `actual_delivery_date` | `DATE` |  | Фактическая дата |

Статусы доставки: `not_started`, `in_progress`, `delivered`, `failed`, `returned`.

### `reviews`

| Поле | Тип | Ограничения | Описание |
|---|---|---|---|
| `review_id` | `SERIAL` | `PRIMARY KEY` | Идентификатор отзыва |
| `order_id` | `INT` | `NOT NULL`, `FOREIGN KEY`, `ON DELETE CASCADE` | Заказ |
| `product_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | Товар |
| `customer_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | Клиент |
| `rating` | `INT` | `NOT NULL`, `CHECK (rating BETWEEN 1 AND 5)` | Оценка |
| `review_text` | `TEXT` |  | Текст отзыва |
| `review_date` | `DATE` | `NOT NULL` | Дата отзыва |

## Первичные ключи

Все основные таблицы используют surrogate key:

- `channel_id`
- `customer_id`
- `category_id`
- `product_id`
- `order_id`
- `order_item_id`
- `payment_id`
- `delivery_id`
- `review_id`

## Внешние ключи

Внешние ключи обеспечивают ссылочную целостность между заказами, клиентами, товарами, оплатами, доставками и отзывами. Для зависимых записей заказа используется `ON DELETE CASCADE`.

## Check constraints

Ограничения `CHECK` контролируют:

- неотрицательные цены и себестоимость;
- положительное количество товара;
- скидку от 0 до 100%;
- допустимые статусы заказов, оплат и доставок;
- рейтинг от 1 до 5.

## Unique constraints

- `marketing_channels.channel_name` — уникальное название канала.
- `categories.category_name` — уникальное название категории.
- `payments.order_id` — одна оплата на один заказ.
- `deliveries.order_id` — одна доставка на один заказ.

## Индексы

Индексы из `sql/04_indexes.sql` используются для ускорения:

- соединений по внешним ключам;
- фильтрации заказов по дате и статусу;
- анализа клиентов, товаров, категорий и каналов;
- запросов по оплатам и доставкам.

## Представления

- `v_order_details`
- `v_customer_orders`
- `v_product_sales`
- `v_delivery_performance`

Представления упрощают повторное использование расчетов и делают аналитические запросы короче.

## Функции

| Функция | Назначение |
|---|---|
| `get_order_revenue(p_order_id INT)` | Расчет выручки по заказу |
| `get_order_gross_profit(p_order_id INT)` | Расчет валовой прибыли по заказу |
| `get_customer_segment(p_orders_count INT, p_total_revenue NUMERIC)` | Определение сегмента клиента |
| `get_delivery_result(p_planned_date DATE, p_actual_date DATE)` | Определение результата доставки |

## Процедуры

| Процедура | Назначение |
|---|---|
| `update_order_status` | Обновление статуса заказа |
| `update_payment_status` | Обновление статуса оплаты |
| `deactivate_product` | Деактивация товара |
| `create_single_product_order` | Создание простого заказа из одного товара |
