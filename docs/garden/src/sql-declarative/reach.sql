-- --8<-- [start:reach]
-- reach(x, y) :- edge(x, y).
-- reach(x, z) :- reach(x, y), edge(y, z).
WITH RECURSIVE reach(x, y) AS (
  SELECT src, dst FROM edge
  UNION
  SELECT r.x, e.dst FROM reach AS r JOIN edge AS e ON e.src = r.y
)
SELECT x, y FROM reach ORDER BY x, y;
-- --8<-- [end:reach]

-- --8<-- [start:union-all]
-- С UNION ALL дубли не отбрасываются, и на цикле a -> b -> a
-- приращение никогда не станет пустым. LIMIT внутри рекурсивного
-- SELECT — расширение SQLite: он ограничивает число строк и
-- останавливает рекурсию.
WITH RECURSIVE reach(x, y) AS (
  SELECT src, dst FROM edge
  UNION ALL
  SELECT r.x, e.dst FROM reach AS r JOIN edge AS e ON e.src = r.y
  LIMIT 1000
)
SELECT count(*) AS rows, count(DISTINCT x || y) AS distinct_pairs FROM reach;
-- --8<-- [end:union-all]
