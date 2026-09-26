// Хост для модулей, сгенерированных fsmc. Работает и в Node, и в браузере:
// зависимостей нет, только стандартный WebAssembly API.
//
// Модуль сам ведёт автомат; хост лишь
//   * даёт функции вывода (env.print_str / print_int / print_end),
//   * кладёт строковые аргументы событий в линейную память через alloc,
//   * читает описание машины из пользовательской секции fsm.meta.
//
//   const m = await FsmMachine.load(bytes, { onLine: console.log });
//   m.send("pin", "4321");     // → { status: "moved", from: "PinWait", to: "Menu", output: [...] }

const STATUS = ["moved", "ignored", "unhandled"];
const utf8 = new TextEncoder();
const text = new TextDecoder();

export class FsmMachine {
  static async load(bytes, { onLine = () => {} } = {}) {
    const module = await WebAssembly.compile(bytes);
    const sections = WebAssembly.Module.customSections(module, "fsm.meta");
    if (!sections.length) throw new Error("в модуле нет секции fsm.meta — он собран не fsmc?");
    const meta = JSON.parse(text.decode(sections[0]));
    const machine = new FsmMachine(meta, onLine);
    const instance = await WebAssembly.instantiate(module, { env: machine.#imports() });
    machine.#bind(instance);
    machine.reset();
    return machine;
  }

  #exports;
  #line = "";
  #output = [];

  constructor(meta, onLine) {
    this.meta = meta;
    this.onLine = onLine;
  }

  #imports() {
    return {
      print_str: (ptr) => { this.#line += this.#readString(ptr); },
      print_int: (n) => { this.#line += String(n); },
      print_end: () => {
        this.#output.push(this.#line);
        this.onLine(this.#line);
        this.#line = "";
      },
    };
  }

  #bind(instance) {
    this.#exports = instance.exports;
  }

  #memory() {
    // buffer пересоздаётся после memory.grow — берём его каждый раз заново.
    return this.#exports.memory.buffer;
  }

  #readString(ptr) {
    const len = new DataView(this.#memory()).getUint32(ptr, true);
    return text.decode(new Uint8Array(this.#memory(), ptr + 4, len));
  }

  #writeString(s) {
    const data = utf8.encode(s);
    const ptr = this.#exports.alloc(4 + data.length);
    new DataView(this.#memory()).setUint32(ptr, data.length, true);
    new Uint8Array(this.#memory(), ptr + 4, data.length).set(data);
    return ptr;
  }

  reset() {
    this.#exports.init();
    this.#line = "";
  }

  get state() {
    return this.meta.states[this.#exports.state.value];
  }

  get context() {
    const out = {};
    for (const f of this.meta.context) {
      const v = this.#exports[f.export].value;
      out[f.name] = f.type === "string" ? this.#readString(v)
        : f.type === "bool" ? Boolean(v) : v;
    }
    return out;
  }

  get events() {
    return this.meta.events;
  }

  // Отправить событие. args — значения параметров в порядке объявления;
  // строки передаются как есть, числа — как number, bool — как true/false.
  send(name, ...args) {
    const event = this.meta.events.find((e) => e.name === name);
    if (!event) throw new Error(`неизвестное событие '${name}'`);
    if (args.length !== event.params.length) {
      throw new Error(`${name} ожидает ${event.params.length} аргумент(а), передано ${args.length}`);
    }
    const raw = event.params.map((p, i) => {
      const v = args[i];
      if (p.type === "string") return this.#writeString(String(v));
      if (p.type === "bool") return v === true || v === "true" ? 1 : 0;
      const n = Number(v);
      if (!Number.isInteger(n)) throw new Error(`${name}: параметр ${p.name} ожидает целое число, получено '${v}'`);
      return n | 0;
    });
    const from = this.state;
    this.#output = [];
    const status = STATUS[this.#exports[event.export](...raw)];
    return { event: name, args, status, from, to: this.state, output: this.#output };
  }
}

// Сценарий: строка на событие, `событие арг1 арг2 ...`, `#` — комментарий.
// Аргумент с пробелами берётся в двойные кавычки: `say "добрый день"`.
export function parseScenario(source) {
  const events = [];
  source.split("\n").forEach((raw, i) => {
    const words = [...raw.matchAll(/"([^"]*)"|(#.*)|(\S+)/g)]
      .filter((m) => !m[2])
      .map((m) => (m[1] !== undefined ? m[1] : m[3]));
    if (!words.length) return;
    events.push({ name: words[0], args: words.slice(1), line: i + 1 });
  });
  return events;
}
