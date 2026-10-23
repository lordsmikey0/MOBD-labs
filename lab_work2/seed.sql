-- Лабораторная работа №2. Тестовые данные для схемы из marketplace.sql.

BEGIN;

TRUNCATE TABLE public.deliveries, public.payments, public.reviews,
    public.order_items, public.orders, public.cart_items, public.carts,
    public.stock, public.products, public.addresses, public.categories,
    public.sellers, public.users RESTART IDENTITY CASCADE;

-- 250 пользователей: 25 продавцов и 225 покупателей.
INSERT INTO public.users (id, full_name, email, phone, role, created_at)
SELECT g, 'Пользователь ' || g, 'user' || g || '@example.test',
       CASE WHEN g % 9 = 0 THEN NULL ELSE '+7900' || lpad(g::text, 7, '0') END,
       CASE WHEN g <= 25 THEN 'seller' ELSE 'customer' END,
       timestamptz '2026-01-01 00:00:00+00' + g * interval '1 hour'
FROM generate_series(1, 250) AS g;

INSERT INTO public.sellers (id, user_id, store_name, description)
SELECT g, g, 'Магазин №' || g,
       CASE WHEN g % 5 = 0 THEN NULL ELSE 'Учебный продавец ' || g END
FROM generate_series(1, 25) AS g;

INSERT INTO public.categories (id, parent_id, name) VALUES
(1, NULL, 'Электроника'), (2, NULL, 'Дом'), (3, NULL, 'Книги'), (4, NULL, 'Спорт'),
(5, 1, 'Смартфоны'), (6, 1, 'Ноутбуки'), (7, 1, 'Наушники'),
(8, 2, 'Мебель'), (9, 2, 'Освещение'), (10, 3, 'Фантастика'),
(11, 3, 'Учебники'), (12, 4, 'Фитнес');

-- 1500 товаров: разные цены, состояния, заполненность описаний.
INSERT INTO public.products (id, seller_id, category_id, title, description, price, is_active, created_at)
SELECT g, ((g - 1) % 25) + 1, ((g - 1) % 8) + 5,
       CASE (g % 5)
           WHEN 0 THEN 'Смартфон'
           WHEN 1 THEN 'Ноутбук'
           WHEN 2 THEN 'Наушники'
           WHEN 3 THEN 'Лампа'
           ELSE 'Товар'
       END || ' модель ' || g,
       CASE WHEN g % 11 = 0 THEN NULL ELSE 'Описание тестового товара №' || g END,
       (500 + ((g * 137) % 95000))::numeric(12,2),
       g % 10 <> 0,
       timestamptz '2026-02-01 00:00:00+00' + g * interval '10 minutes'
FROM generate_series(1, 1500) AS g;

INSERT INTO public.stock (product_id, quantity)
SELECT g, (g * 13) % 200 FROM generate_series(1, 1500) AS g;

INSERT INTO public.carts (id, user_id)
SELECT g, g + 25 FROM generate_series(1, 200) AS g;

INSERT INTO public.cart_items (cart_id, product_id, quantity)
SELECT c.id, ((c.id * 3 + x.n - 1) % 1500) + 1, x.n
FROM public.carts AS c CROSS JOIN generate_series(1, 2) AS x(n);

INSERT INTO public.addresses (id, user_id, city, street, house, apartment)
SELECT g, g,
       CASE g % 4 WHEN 0 THEN 'Москва' WHEN 1 THEN 'Казань'
                      WHEN 2 THEN 'Санкт-Петербург' ELSE 'Тула' END,
       'Учебная улица', (g % 90 + 1)::text,
       CASE WHEN g % 7 = 0 THEN NULL ELSE (g % 150 + 1)::text END
FROM generate_series(1, 250) AS g;

-- 1200 заказов, каждый получит ровно две позиции.
INSERT INTO public.orders (id, user_id, status, total_amount, created_at)
SELECT g, ((g - 1) % 225) + 26,
       CASE g % 4 WHEN 0 THEN 'pending' WHEN 1 THEN 'confirmed'
                      WHEN 2 THEN 'completed' ELSE 'cancelled' END,
       0,
       timestamptz '2026-03-01 00:00:00+00' + g * interval '25 minutes'
FROM generate_series(1, 1200) AS g;

INSERT INTO public.order_items (order_id, product_id, quantity, unit_price)
SELECT o.id, p.id, x.n, p.price
FROM public.orders AS o
CROSS JOIN generate_series(1, 2) AS x(n)
CROSS JOIN LATERAL (
    SELECT id, price FROM public.products
    WHERE id = ((o.id * 7 + x.n - 1) % 1500) + 1
) AS p;

UPDATE public.orders AS o
SET total_amount = v.amount
FROM (
    SELECT order_id, SUM(quantity * unit_price)::numeric(12,2) AS amount
    FROM public.order_items GROUP BY order_id
) AS v
WHERE o.id = v.order_id;

INSERT INTO public.payments (id, order_id, amount, status, paid_at)
SELECT o.id, o.id, o.total_amount,
       CASE o.status WHEN 'completed' THEN 'paid'
                     WHEN 'cancelled' THEN 'failed' ELSE 'pending' END,
       CASE WHEN o.status = 'completed' THEN o.created_at + interval '15 minutes'
            ELSE NULL END
FROM public.orders AS o;

INSERT INTO public.deliveries (id, order_id, address_id, is_delivered, delivery_status, delivery_date)
SELECT o.id, o.id, o.user_id,
       o.status = 'completed',
       CASE o.status WHEN 'completed' THEN 'delivered'
                     WHEN 'cancelled' THEN 'cancelled'
                     WHEN 'confirmed' THEN 'shipped' ELSE 'pending' END,
       CASE WHEN o.status = 'completed' THEN o.created_at + interval '3 days'
            ELSE NULL END
FROM public.orders AS o;

INSERT INTO public.reviews (id, user_id, product_id, score, comment, created_at)
SELECT g, ((g - 1) % 225) + 26, ((g * 11 - 1) % 1500) + 1,
       (g % 5) + 1,
       CASE WHEN g % 6 = 0 THEN NULL ELSE 'Отзыв на товар №' || g END,
       timestamptz '2026-04-01 00:00:00+00' + g * interval '10 minutes'
FROM generate_series(1, 900) AS g;

SELECT setval(pg_get_serial_sequence('public.users', 'id'), 250, true);
SELECT setval(pg_get_serial_sequence('public.sellers', 'id'), 25, true);
SELECT setval(pg_get_serial_sequence('public.categories', 'id'), 12, true);
SELECT setval(pg_get_serial_sequence('public.products', 'id'), 1500, true);
SELECT setval(pg_get_serial_sequence('public.carts', 'id'), 200, true);
SELECT setval(pg_get_serial_sequence('public.addresses', 'id'), 250, true);
SELECT setval(pg_get_serial_sequence('public.orders', 'id'), 1200, true);
SELECT setval(pg_get_serial_sequence('public.payments', 'id'), 1200, true);
SELECT setval(pg_get_serial_sequence('public.deliveries', 'id'), 1200, true);
SELECT setval(pg_get_serial_sequence('public.reviews', 'id'), 900, true);

COMMIT;

SELECT 'users' AS table_name, COUNT(*) AS rows_count FROM public.users
UNION ALL SELECT 'sellers', COUNT(*) FROM public.sellers
UNION ALL SELECT 'categories', COUNT(*) FROM public.categories
UNION ALL SELECT 'products', COUNT(*) FROM public.products
UNION ALL SELECT 'stock', COUNT(*) FROM public.stock
UNION ALL SELECT 'carts', COUNT(*) FROM public.carts
UNION ALL SELECT 'cart_items', COUNT(*) FROM public.cart_items
UNION ALL SELECT 'addresses', COUNT(*) FROM public.addresses
UNION ALL SELECT 'orders', COUNT(*) FROM public.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM public.order_items
UNION ALL SELECT 'payments', COUNT(*) FROM public.payments
UNION ALL SELECT 'deliveries', COUNT(*) FROM public.deliveries
UNION ALL SELECT 'reviews', COUNT(*) FROM public.reviews
ORDER BY table_name;
