// Тот же результат, что aggregate.sql и host.py, — методами массивов JS.
const dept = [[1, "compilers"], [2, "runtime"], [3, "docs"]];
const emp = [
  { name: "ada", dept: 1, salary: 300 }, { name: "bob", dept: 1, salary: 200 },
  { name: "eve", dept: 2, salary: 250 }, { name: "dan", dept: 2, salary: 250 },
  { name: "kim", dept: null, salary: 150 }, { name: "lee", dept: 1, salary: 200 },
];

// --8<-- [start:pipeline]
const titles = new Map(dept);
const groups = Object.groupBy(
  emp.filter((e) => e.dept !== null),          // JOIN отбросил бы kim
  (e) => titles.get(e.dept),
);
const result = Object.entries(groups)
  .map(([title, es]) => [title, es.length, es.reduce((s, e) => s + e.salary, 0)])
  .filter(([, n]) => n >= 2)                   // HAVING
  .sort((a, b) => b[2] - a[2]);                // ORDER BY total DESC
// --8<-- [end:pipeline]

console.log(JSON.stringify(result));
