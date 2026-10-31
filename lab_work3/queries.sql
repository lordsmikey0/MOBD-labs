-- Лабораторная работа №3 — Многотабличные запросы и аналитические представления
-- СПИСОК ЗАПРОСОВ


-- Задание 1
SELECT
	p.title AS product,
	c.name AS category,
	s.store_name AS seller
FROM products AS p
INNER JOIN categories AS c
	ON p.category_id = c.id
INNER JOIN sellers AS s
	ON p.seller_id = s.id
LIMIT 20;


-- Задание 2
SELECT
    p.id,
    p.title,
    r.score
FROM products AS p
LEFT JOIN reviews AS r
    ON p.id = r.product_id
WHERE r.id IS NULL
LIMIT 20;


-- Задание 3
SELECT
    c.name AS category,
    COUNT(p.id) AS product_count,
    ROUND(AVG(p.price), 2) AS average_price
FROM categories AS c
LEFT JOIN products AS p
    ON p.category_id = c.id
GROUP BY c.id, c.name
ORDER BY product_count DESC, c.id;


--Задание 4
SELECT
    s.store_name AS seller,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM sellers AS s
INNER JOIN products AS p
    ON p.seller_id = s.id
INNER JOIN order_items AS oi
    ON oi.product_id = p.id
GROUP BY s.id, s.store_name
HAVING SUM(oi.quantity * oi.unit_price) > 6450000
ORDER BY revenue DESC
LIMIT 20;


--Задание 5.1 - скалярный подзапрос
SELECT
    p.title,
    p.price
FROM products AS p
WHERE p.price > (
    SELECT AVG(price)
    FROM products
)
ORDER BY p.price DESC
LIMIT 20;


-- Задание 5.2 - запрос с IN
SELECT
    p.title,
    p.price,
    p.seller_id
FROM products AS p
WHERE p.seller_id IN (
    SELECT s.id
    FROM sellers AS s
    WHERE s.store_name ILIKE '%№5'
)
LIMIT 15;

-- Задание 5.3 - запрос с EXISTS
SELECT
    s.id,
    s.store_name
FROM sellers AS s
WHERE EXISTS (
    SELECT 1
    FROM products AS p
    WHERE p.seller_id = s.id
)
LIMIT 15;

-- Задание 6.1 - CTE
WITH seller_revenue AS (
    SELECT
        p.seller_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products AS p
    INNER JOIN order_items AS oi
        ON p.id = oi.product_id
    GROUP BY p.seller_id
)
SELECT
    s.store_name AS seller,
    sr.revenue
FROM seller_revenue AS sr
INNER JOIN sellers AS s
    ON sr.seller_id = s.id
WHERE sr.revenue > 100000
ORDER BY sr.revenue DESC
LIMIT 15;

-- Задание 6.2 - Рекурсивный CTE
WITH RECURSIVE category_tree AS (
    SELECT
        id,
        name,
        parent_id,
        0 AS depth
    FROM categories
    WHERE id = 1

    UNION ALL

    SELECT
        c.id,
        c.name,
        c.parent_id,
        ct.depth + 1
    FROM categories AS c
    INNER JOIN category_tree AS ct
        ON c.parent_id = ct.id
)
SELECT
    id,
    name,
    parent_id,
    depth
FROM category_tree
ORDER BY depth, id
LIMIT 20;


-- Задание 7.1 - Создание представления №1
CREATE OR REPLACE VIEW category_statistics AS
SELECT
    c.name AS category,
    COUNT(p.id) AS product_count,
    ROUND(AVG(p.price), 2) AS average_price
FROM categories AS c
LEFT JOIN products AS p
    ON p.category_id = c.id
GROUP BY c.id, c.name;

-- Задание 7.2 - Обращение к представлению №1
SELECT *
FROM category_statistics
ORDER BY product_count DESC, category
LIMIT 20;

-- Задание 7.3 - Создание представления №2
CREATE OR REPLACE VIEW seller_revenue_report AS
SELECT
    s.id AS seller_id,
    s.store_name AS seller,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM sellers AS s
INNER JOIN products AS p
    ON p.seller_id = s.id
INNER JOIN order_items AS oi
    ON oi.product_id = p.id
GROUP BY s.id, s.store_name;

-- Задание 7.4 - Обращение к представлению №2
SELECT *
FROM seller_revenue_report
WHERE revenue > 100000
ORDER BY revenue DESC
LIMIT 20;
