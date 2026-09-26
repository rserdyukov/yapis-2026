// Запустить скомпилированный автомат на сценарии событий.
//
//   node runtime/run.mjs build/atm.wasm scenarios/01_success.events
//
// Печатает протокол реакций и итоговое состояние — в том же формате,
// что reference/reference.py, чтобы тесты сравнивали вывод построчно.
// Флаг --trace добавляет строку на каждое событие: откуда, куда, статус.

import { readFileSync } from "node:fs";
import { FsmMachine, parseScenario } from "./fsm-host.mjs";

const args = process.argv.slice(2);
const trace = args.includes("--trace");
const [wasmPath, scenarioPath] = args.filter((a) => !a.startsWith("--"));
if (!wasmPath) {
  console.error("использование: node run.mjs <prog.wasm> [сценарий.events] [--trace]");
  process.exit(2);
}

const machine = await FsmMachine.load(readFileSync(wasmPath), {
  onLine: (line) => console.log(line),
});
const scenario = parseScenario(readFileSync(scenarioPath ?? 0, "utf8"));
let exitCode = 0;
for (const ev of scenario) {
  try {
    const r = machine.send(ev.name, ...ev.args);
    if (trace) console.log(`  · ${r.event}(${r.args.join(", ")}): ${r.from} → ${r.to} [${r.status}]`);
    if (r.status === "unhandled") {
      console.error(`строка ${ev.line}: событие ${ev.name} не обработано в состоянии ${r.from}`);
    }
  } catch (e) {
    console.error(`строка ${ev.line}: ${e.message}`);
    exitCode = 1;
  }
}
console.log(`Итоговое состояние: ${machine.state}`);
process.exit(exitCode);
