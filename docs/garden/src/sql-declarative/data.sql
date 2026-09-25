-- Общие данные для всех примеров статьи «SQL: декларативность».
CREATE TABLE dept (
  id    INTEGER PRIMARY KEY,
  title TEXT NOT NULL
);
CREATE TABLE emp (
  id         INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  dept_id    INTEGER REFERENCES dept(id),  -- может быть NULL
  salary     INTEGER NOT NULL,
  manager_id INTEGER REFERENCES emp(id)    -- NULL у руководителя верхнего уровня
);
INSERT INTO dept VALUES (1, 'compilers'), (2, 'runtime'), (3, 'docs');
INSERT INTO emp VALUES
  (1, 'ada', 1, 300, NULL),
  (2, 'bob', 1, 200, 1),
  (3, 'eve', 2, 250, 1),
  (4, 'dan', 2, 250, 3),
  (5, 'kim', NULL, 150, 3),
  (6, 'lee', 1, 200, 2);
-- Граф из примера Datalog на странице различающих примеров.
CREATE TABLE edge (src TEXT NOT NULL, dst TEXT NOT NULL);
INSERT INTO edge VALUES ('a', 'b'), ('b', 'a'), ('b', 'c');
