-- --8<-- [start:nulls]
-- Кто не работает в отделе 1? kim (dept_id IS NULL) не попадёт:
-- NULL <> 1 даёт UNKNOWN, а WHERE пропускает только TRUE.
SELECT 'not_in_1', group_concat(name, ',' ORDER BY name) FROM emp WHERE dept_id <> 1;

-- Кто никем не руководит? У ada manager_id IS NULL, поэтому
-- x NOT IN (…, NULL) ни для кого не бывает TRUE — ответ пуст.
SELECT 'not_managers', count(*) FROM emp
WHERE id NOT IN (SELECT manager_id FROM emp);

-- Та же мысль через NOT EXISTS: сравнение с NULL просто не находит пару.
SELECT 'not_managers', group_concat(name, ',' ORDER BY name) FROM emp AS e
WHERE NOT EXISTS (SELECT 1 FROM emp AS s WHERE s.manager_id = e.id);
-- --8<-- [end:nulls]

-- --8<-- [start:order]
-- Порядок без ORDER BY — свойство плана, а не запроса.
SELECT 'default', group_concat(name, ',') FROM (SELECT name FROM emp WHERE salary >= 200);

CREATE INDEX emp_salary ON emp(salary);
SELECT 'with_index', group_concat(name, ',') FROM (SELECT name FROM emp WHERE salary >= 200);

PRAGMA reverse_unordered_selects = ON;   -- расширение SQLite для тестов
SELECT 'reversed', group_concat(name, ',') FROM (SELECT name FROM emp WHERE salary >= 200);

-- Порядок внутри агрегата тоже нужно заказать явно (синтаксис SQLite 3.44+).
SELECT 'order_by', group_concat(name, ',' ORDER BY name) FROM emp WHERE salary >= 200;
-- --8<-- [end:order]
