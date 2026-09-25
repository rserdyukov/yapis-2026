// Спецификация (ES2015+) требует proper tail calls в строгом коде.
// V8 (и, значит, Node.js) их не реализует: глубокая хвостовая рекурсия переполняет стек.

function countDown(n) {
  "use strict";
  if (n === 0) return "done";
  return countDown(n - 1);          // хвостовая позиция по ECMA-262 §Tail Position Calls
}

for (const n of [1e3, 1e6]) {
  try {
    console.log(n, countDown(n));
  } catch (e) {
    console.log(n, e.constructor.name + ": " + e.message);
  }
}
