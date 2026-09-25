// this определяется способом вызова, а не местом объявления.
// Файл .cjs — нестрогий код; вторая часть включает strict внутри функции.

// --8<-- [start:callback]
const counter = {
  n: 0,
  tick() {
    [1, 2].forEach(function () {
      // обычная функция, вызванная без получателя: в нестрогом коде this — глобальный объект
      console.log("function:", this === globalThis, this.n);
    });
    [1, 2].forEach(() => {
      this.n++;                              // стрелка берёт this из tick
    });
    console.log("arrow:", this.n);
  },
};
counter.tick();
// --8<-- [end:callback]

// --8<-- [start:detached]
const detached = counter.tick;
detached();                                  // this === globalThis: у него нет n
console.log("global n:", globalThis.n);      // undefined++ создало глобальное свойство

function strictDetached() {
  "use strict";
  const obj = { n: 0, inc() { return ++this.n; } };
  const f = obj.inc;
  try {
    f();                                     // в строгом коде this === undefined
  } catch (e) {
    console.log("strict:", e.constructor.name + ": " + e.message);
  }
}
strictDetached();
// --8<-- [end:detached]
