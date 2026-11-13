-- Лабораторная работа №4. Оконные функции и аналитика данных.
-- СПИСОК ЗАПРОСОВ


-- Задание 1
SELECT
    c.name AS category,
    p.id AS product_id,
    p.title,
    p.price,
    ROW_NUMBER() OVER w AS row_num,
    RANK() OVER w AS price_rank,
    DENSE_RANK() OVER w AS dense_rank
FROM products AS p
JOIN categories AS c ON c.id = p.category_id
WINDOW w AS (
    PARTITION BY p.category_id
    ORDER BY p.price DESC
)
ORDER BY c.name, p.price DESC, p.id;

-- Но в сгенерированных данных нет одинаковых цен, поэтому

WITH demo(title, price) AS (
    VALUES
        ('Ноутбук', 100000),
        ('Смартфон', 70000),
        ('Планшет', 70000),
        ('Монитор', 40000)
)
SELECT
    title,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC, title) AS row_num,
    RANK() OVER (ORDER BY price DESC) AS price_rank,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank
FROM demo
ORDER BY row_num;

-- Здесь демонстрация более явная

-- Задание 2
WITH ranked_products AS (
    SELECT
        c.id AS category_id,
        c.name AS category,
        p.id AS product_id,
        p.title,
        p.price,
        ROW_NUMBER() OVER (
            PARTITION BY p.category_id
            ORDER BY p.price DESC NULLS LAST, p.id
        ) AS place
    FROM products AS p
    JOIN categories AS c ON c.id = p.category_id
)
SELECT category, product_id, title, price, place
FROM ranked_products
WHERE place <= 3
ORDER BY category, category_id, place;


-- Задание 3
WITH daily AS (
    SELECT
        (o.created_at AT TIME ZONE 'Europe/Moscow')::date AS day,
        SUM(oi.quantity * oi.unit_price) AS day_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY 1
)
SELECT
    day,
    day_revenue,
    SUM(day_revenue) OVER (
        ORDER BY day
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM daily
ORDER BY day;


-- Задание 4
WITH seller_sales AS (
    SELECT
        p.category_id,
        p.seller_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.id
    JOIN products AS p ON p.id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY p.category_id, p.seller_id
)
SELECT
    category_id,
    seller_id,
    revenue,
    100 * revenue / NULLIF(SUM(revenue) OVER (PARTITION BY category_id),
    0
    ) AS share_pct
FROM seller_sales;


-- Задание 5
WITH daily AS (
    SELECT
        (o.created_at AT TIME ZONE 'Europe/Moscow')::date AS day,
        SUM(oi.quantity * oi.unit_price) AS day_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY 1
)
SELECT
    day,
    day_revenue,
    LAG(day_revenue) OVER (ORDER BY day) AS previous_revenue,
    LEAD(day_revenue) OVER (ORDER BY day) AS next_revenue,
    day_revenue - LAG(day_revenue) OVER (ORDER BY day) AS growth
FROM daily
ORDER BY day;


-- Задание 6
WITH seller_sales AS (
    SELECT
        p.category_id,
        p.seller_id,
        SUM(oi.quantity * oi.unit_price) AS seller_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.id
    JOIN products AS p ON p.id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY p.category_id, p.seller_id
),
category_totals AS (
    SELECT category_id, SUM(seller_revenue) AS category_revenue
    FROM seller_sales
    GROUP BY category_id
)
SELECT
    c.name AS category,
    s.store_name AS seller,
    ss.seller_revenue,
    ct.category_revenue,
    ROUND(100.0 * ss.seller_revenue / NULLIF(ct.category_revenue, 0), 2) AS share_pct
FROM seller_sales AS ss
JOIN category_totals AS ct ON ct.category_id = ss.category_id
JOIN categories AS c ON c.id = ss.category_id
JOIN sellers AS s ON s.id = ss.seller_id
ORDER BY c.name, c.id, ss.seller_revenue DESC, s.id;
