// var: одна переменная на функцию; let: новая переменная на каждую итерацию.

// --8<-- [start:loop]
const withVar = [];
for (var i = 0; i < 3; i++) withVar.push(() => i);

const withLet = [];
for (let j = 0; j < 3; j++) withLet.push(() => j);

console.log(withVar.map((f) => f()), withLet.map((f) => f()));
console.log(typeof i, typeof j);          // i «вытекла» из цикла, j — нет
// --8<-- [end:loop]

// --8<-- [start:hoist]
function hoisting() {
  console.log(v);                          // объявление поднято, значение — нет
  var v = 1;
  try {
    console.log(l);
  } catch (e) {
    console.log(e.constructor.name + ": " + e.message);   // временная мёртвая зона
  }
  let l = 2;
}
hoisting();
// --8<-- [end:hoist]
