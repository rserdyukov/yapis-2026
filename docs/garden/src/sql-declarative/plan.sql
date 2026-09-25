-- Один и тот же запрос до и после CREATE INDEX.
-- --8<-- [start:before]
EXPLAIN QUERY PLAN
SELECT e.name
FROM dept AS d JOIN emp AS e ON e.dept_id = d.id
WHERE d.title = 'runtime';
-- --8<-- [end:before]

-- --8<-- [start:after]
CREATE INDEX emp_dept ON emp(dept_id);

EXPLAIN QUERY PLAN
SELECT e.name
FROM dept AS d JOIN emp AS e ON e.dept_id = d.id
WHERE d.title = 'runtime';
-- --8<-- [end:after]

-- --8<-- [start:result]
SELECT e.name
FROM dept AS d JOIN emp AS e ON e.dept_id = d.id
WHERE d.title = 'runtime'
ORDER BY e.name;
-- --8<-- [end:result]
