// Модуль ES (.mjs) всегда строгий — директива "use strict" не нужна.

try {
  undeclared = 42;
} catch (e) {
  console.log("module:", e.constructor.name + ": " + e.message);
}
console.log("this at top level:", this);
