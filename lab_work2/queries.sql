-- Лабораторная работа №2 — базовые SQL-запросы и фильтрация.
-- Запускать после seed.sql; запросы не изменяют данные.

-- 1. DISTINCT: уникальные сочетания категории и активности товара,
--    с псевдонимами столбцов.
SELECT DISTINCT category_id AS category, is_active AS available
FROM public.products
ORDER BY category, available;

-- 2. Фильтрация AND / OR со скобками.
--    Активные товары: либо недорогие смартфоны, либо дорогие ноутбуки.
SELECT id, title, price, category_id
FROM public.products
WHERE is_active = TRUE
  AND ((title ILIKE 'Смартфон%' AND price < 20000)
       OR (title ILIKE 'Ноутбук%' AND price >= 20000))
ORDER BY price DESC
LIMIT 15;

-- 3. BETWEEN: товары в диапазоне цен включительно.
SELECT id, title, price
FROM public.products
WHERE price BETWEEN 1000 AND 5000
ORDER BY price, id
LIMIT 15;

-- 4. IN: товары выбранных категорий.
SELECT id, title, category_id, price
FROM public.products
WHERE category_id IN (5, 6, 7)
ORDER BY category_id, id
LIMIT 15;

-- 5. ILIKE: нечувствительный к регистру поиск подстроки.
SELECT id, title, price
FROM public.products
WHERE title ILIKE '%смартфон%'
ORDER BY id
LIMIT 15;

-- 6. IS NULL: товары без описания.
SELECT id, title, description
FROM public.products
WHERE description IS NULL
ORDER BY id
LIMIT 15;

-- 7. Сортировка по двум столбцам в разных направлениях.
SELECT id, category_id, title, price
FROM public.products
ORDER BY category_id ASC, price DESC, id ASC
LIMIT 20;

-- 8. Постраничный вывод: вторая страница из 20 товаров.
--    ORDER BY id гарантирует стабильный порядок для пагинации.
SELECT id, title, price
FROM public.products
ORDER BY id ASC
LIMIT 20 OFFSET 20;
