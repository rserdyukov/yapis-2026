// Аналог doesNotUnderstand: в JavaScript: ловушка get объекта Proxy
// перехватывает КАЖДОЕ обращение к свойству, а не только неизвестные.
"use strict";

function loggingProxy(subject) {
  let invocationCount = 0;
  return new Proxy(subject, {
    get(target, name, receiver) {
      if (name === "invocationCount") return invocationCount;
      const value = Reflect.get(target, name, receiver);
      if (typeof value !== "function") return value;
      return (...args) => {
        invocationCount += 1;
        console.log(`performing ${String(name)}(${args.join(", ")})`);
        return value.apply(target, args);     // aMessage sendTo: subject
      };
    },
  });
}

const p = loggingProxy([]);
p.push(3);
p.push(4);
console.log("indexOf(4) =", p.indexOf(4));
console.log("length =", p.length);            // не функция — отдаём как есть
console.log("invocationCount =", p.invocationCount);
