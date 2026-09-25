// JavaScript: аргументы вычисляются до вызова; лень — через генераторы
// или явные «thunk» — функции без параметров.
function trace(name, value) {
  console.log(`  вычисляю ${name}`);
  return value;
}
const constOne = (_x) => 1;
console.log("constOne:", constOne(trace("аргумент", 42)));

// Отложенное значение вручную: функция без параметров + мемоизация.
function lazy(f) {
  let done = false, value;
  return () => {
    if (!done) { value = f(); done = true; }
    return value;
  };
}
const expensive = lazy(() => trace("expensive", 6 * 7));
console.log("thunk создан");
console.log(expensive(), expensive()); // вычисляется один раз

function* fibs() {
  let [a, b] = [0n, 1n];
  for (;;) { yield a; [a, b] = [b, a + b]; }
}
function take(n, it) {
  const out = [];
  for (const x of it) { if (out.length >= n) break; out.push(x); }
  return out;
}
console.log(take(10, fibs()).join(" "));

// && и || — единственные «нестрогие» места: правый операнд может не вычисляться.
false && trace("правый операнд", true);
console.log("после false && ...");
