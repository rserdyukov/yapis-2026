// Таблица нестрогого равенства == (IsLooselyEqual) против === и Object.is.

// --8<-- [start:table]
const pairs = [
  ["0", "''", 0, ""],
  ["0", "'0'", 0, "0"],
  ["''", "'0'", "", "0"],
  ["false", "'0'", false, "0"],
  ["false", "''", false, ""],
  ["null", "undefined", null, undefined],
  ["null", "0", null, 0],
  ["null", "false", null, false],
  ["[]", "false", [], false],
  ["[]", "![]", [], ![]],
  ["[0]", "false", [0], false],
  ["'\\n'", "0", "\n", 0],
  ["NaN", "NaN", NaN, NaN],
];
for (const [a, b, x, y] of pairs) {
  console.log(`${(a + " == " + b).padEnd(18)} ${String(x == y).padEnd(5)}  === ${x === y}`);
}
// --8<-- [end:table]

// --8<-- [start:nan]
console.log(typeof null, typeof undefined, typeof function () {});
console.log(NaN === NaN, [NaN].indexOf(NaN), [NaN].includes(NaN));
console.log(Object.is(NaN, NaN), Object.is(0, -0), 0 === -0);
// --8<-- [end:nan]
