// Те же приёмы в JavaScript: прототипы и Proxy.

// Делегирование: аналог __index = таблица
const Account = {
  deposit(v) { this.balance += v; },
  report() { return `${this.owner}: ${this.balance}`; },
};
const a = Object.create(Account);   // [[Prototype]] = Account
a.owner = "Ann"; a.balance = 100;
a.deposit(50);
console.log(a.report(), Object.hasOwn(a, "deposit"));

// Прокси с логированием: аналог __index/__newindex-функций,
// но ловушки срабатывают на КАЖДОЕ обращение, а не только на отсутствующий ключ
const target = { port: 80 };
const cfg = new Proxy(target, {
  get(t, k, r) { console.log(`get ${String(k)}`); return Reflect.get(t, k, r); },
  set(t, k, v, r) { console.log(`set ${String(k)} = ${v}`); return Reflect.set(t, k, v, r); },
});
cfg.port = cfg.port + 1;
console.log(target.port);

// Операторы перегрузить нельзя: + вызывает valueOf/toString (ToPrimitive)
const v = { x: 1, y: 2, valueOf() { return 42; } };
console.log(v + 1, `${{ toString() { return "(1, 2)"; } }}`);
