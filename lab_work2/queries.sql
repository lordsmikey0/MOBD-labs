-- Лабораторная работа №2 — базовые SQL-запросы и фильтрация.
-- СПИСОК ЗАПРОСОВ


-- Получение количества сгенерированных записей в таблицах
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM public.users
UNION ALL
SELECT 'products', COUNT(*) FROM public.products
UNION ALL
SELECT 'orders', COUNT(*) FROM public.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM public.order_items
UNION ALL
SELECT 'deliveries', COUNT(*) FROM public.deliveries;


-- Задание 2
SELECT DISTINCT title AS product_name, price AS product_price
FROM public.products
ORDER BY product_price, product_name
LIMIT 10;


-- Задание 3
SELECT title AS product_name, price AS product_price
FROM public.products
WHERE is_active = TRUE AND ((price < 2000) OR (price > 50000))
LIMIT 20;

-- Задание 4.1
SELECT title AS product_name, price AS product_price
FROM public.products
WHERE price BETWEEN 5000 AND 15000
LIMIT 15;

-- Задание 4.2
SELECT title AS product_name, price AS product_price, category_id AS product_category
FROM public.products
WHERE category_id IN (5, 6, 7)
LIMIT 10;

-- Задание 4.3
SELECT title AS product_name, price AS product_price
FROM public.products
WHERE title ILIKE '%лампа%'
LIMIT 10;

-- Задание 4.4
SELECT title AS product_title, price AS product_price
FROM public.products
WHERE description IS NULL
LIMIT 10;

-- Задание 5
SELECT id, user_id, status, total_amount, created_at
FROM public.orders
ORDER BY status ASC, total_amount DESC
LIMIT 15;

-- Задание 6
SELECT id, title AS product_title, price AS product_price, description AS product_desc
FROM public.products
WHERE description IS NOT NULL
ORDER BY title ASC, price ASC, id ASC
LIMIT 10
OFFSET 10;
