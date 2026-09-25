-- The same SQL statements run on PostgreSQL and SQLite.
WITH t(x) AS (VALUES (1), (1), (2))
SELECT ALL x FROM t ORDER BY x;

WITH t(x) AS (VALUES (1), (1), (2))
SELECT DISTINCT x FROM t ORDER BY x;

SELECT CASE WHEN NULL = NULL THEN 'true'
            WHEN NOT (NULL = NULL) THEN 'false'
            ELSE 'unknown' END;
