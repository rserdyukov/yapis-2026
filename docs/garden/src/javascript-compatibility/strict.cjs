// Нестрогий и строгий режим в одном файле CommonJS (.cjs — по умолчанию нестрогий).
// "use strict" в начале тела функции включает строгий режим только для неё.

// --8<-- [start:modes]
function sloppy() {
  undeclared = 42;                 // опечатка создаёт свойство глобального объекта
  const frozen = Object.freeze({ x: 1 });
  frozen.x = 2;                    // молча игнорируется
  console.log("sloppy:", globalThis.undeclared, frozen.x);
}

function strict() {
  "use strict";
  try { undeclared2 = 42; } catch (e) { console.log("strict:", e.constructor.name + ": " + e.message); }
  const frozen = Object.freeze({ x: 1 });
  try { frozen.x = 2; } catch (e) { console.log("strict:", e.constructor.name + ": " + e.message); }
}

sloppy();
strict();
// --8<-- [end:modes]

// --8<-- [start:legacy]
// Устаревшие конструкции работают в нестрогом коде и запрещены в строгом.
const bodies = [
  "with (Math) return PI",
  "return 010",
  "'use strict'; return 010",
  "'use strict'; with (Math) return PI",
];
for (const body of bodies) {
  try {
    console.log(body.padEnd(37), "->", new Function(body)());
  } catch (e) {
    console.log(body.padEnd(37), "->", e.constructor.name + ": " + e.message);
  }
}
// --8<-- [end:legacy]
