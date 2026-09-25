-- --8<-- [start:group]
SELECT d.title, count(*) AS n, sum(e.salary) AS total, max(e.salary) AS top
FROM emp AS e JOIN dept AS d ON d.id = e.dept_id
GROUP BY d.title
HAVING count(*) >= 2
ORDER BY total DESC;
-- --8<-- [end:group]

-- --8<-- [start:window]
SELECT name, dept_id, salary,
       rank()      OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
       sum(salary) OVER (PARTITION BY dept_id)                      AS dept_total
FROM emp
WHERE dept_id IS NOT NULL
ORDER BY dept_id, rnk, name;
-- --8<-- [end:window]
