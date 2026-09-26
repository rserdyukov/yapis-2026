// Playground компилятора FSM.
//
// Python-компилятор (examples/atm-lang/fsmc) исполняется в Pyodide; файлы
// fsmc-bundle.zip, fsm-host.mjs и examples.json кладёт рядом хук сборки
// сайта (tools/site_hooks.py → tools/playground_bundle.py).

import { FsmMachine, parseScenario } from "./fsm-host.mjs";

// Версии зафиксированы: сайт должен собираться и работать воспроизводимо.
const PYODIDE = "https://cdn.jsdelivr.net/pyodide/v314.0.7/full/";
const MERMAID = "https://cdn.jsdelivr.net/npm/mermaid@11.17.2/dist/mermaid.esm.min.mjs";
const DRAFT_KEY = "fsm-playground-draft";

const $ = (id) => document.getElementById(id);
const ui = {
  example: $("pg-example"), frontend: $("pg-frontend"), compile: $("pg-compile"),
  status: $("pg-status"), source: $("pg-source"), download: $("pg-download"),
  diags: $("pg-diags"), diagram: $("pg-diagram"), wat: $("pg-wat"), ast: $("pg-ast"),
  state: $("pg-state"), context: $("pg-context"), buttons: $("pg-buttons"),
  scenario: $("pg-scenario"), events: $("pg-events"), run: $("pg-run"),
  reset: $("pg-reset"), log: $("pg-log"),
};

let pyodide = null;
let compileFn = null;
let examples = [];
let machine = null;
let wasmUrl = null;
let lastResult = null;
let mermaidLib = null;

// ------------------------------------------------------------------ вкладки

function showTab(name) {
  document.querySelectorAll(".fsm-pg__tabs [role=tab]").forEach((b) => {
    b.setAttribute("aria-selected", String(b.dataset.tab === name));
  });
  document.querySelectorAll(".fsm-pg__tab").forEach((p) => {
    p.hidden = p.dataset.panel !== name;
  });
  if (name === "diagram") renderDiagram();
}
document.querySelectorAll(".fsm-pg__tabs [role=tab]").forEach((b) => {
  b.addEventListener("click", () => showTab(b.dataset.tab));
});

// ------------------------------------------------------------------ загрузка

async function boot() {
  try {
    examples = await (await fetch("examples.json")).json();
    fillExamples();
    const draft = localStorage.getItem(DRAFT_KEY);
    loadExample(examples[0].id, draft);

    status("Загрузка Pyodide…");
    const { loadPyodide } = await import(PYODIDE + "pyodide.mjs");
    pyodide = await loadPyodide({ indexURL: PYODIDE });
    status("Загрузка компилятора…");
    const bundle = await (await fetch("fsmc-bundle.zip")).arrayBuffer();
    pyodide.unpackArchive(bundle, "zip", { extractDir: "/home/pyodide/fsmc-lib" });
    pyodide.runPython(`
import sys
sys.path.insert(0, "/home/pyodide/fsmc-lib")
from fsmc.web import compile_json
`);
    compileFn = pyodide.globals.get("compile_json");
    ui.compile.disabled = false;
    await compile();
  } catch (e) {
    status("Не удалось загрузить: " + e.message, "error");
    console.error(e);
  }
}

function status(text, kind = "") {
  ui.status.textContent = text;
  ui.status.dataset.kind = kind;
}

function fillExamples() {
  const groups = new Map();
  for (const ex of examples) {
    if (!groups.has(ex.group)) {
      const g = document.createElement("optgroup");
      g.label = ex.group;
      groups.set(ex.group, g);
      ui.example.append(g);
    }
    groups.get(ex.group).append(new Option(ex.title, ex.id));
  }
  const draft = new Option("Черновик (ваши правки)", "__draft");
  draft.hidden = true;
  ui.example.append(draft);
}

function loadExample(id, draft = null) {
  const ex = examples.find((e) => e.id === id) ?? examples[0];
  ui.example.value = draft ? "__draft" : ex.id;
  ui.example.options[ui.example.selectedIndex].hidden = false;
  ui.source.value = draft ?? ex.source;
  ui.scenario.replaceChildren(...Object.keys(ex.scenarios).map((k) => new Option(k, k)));
  ui.scenario.append(new Option("свой", "__own"));
  ui.events.value = Object.values(ex.scenarios)[0] ?? "";
}

ui.example.addEventListener("change", () => {
  if (ui.example.value === "__draft") return;
  localStorage.removeItem(DRAFT_KEY);
  loadExample(ui.example.value);
  compile();
});
ui.scenario.addEventListener("change", () => {
  const ex = examples.find((e) => e.id === ui.example.value);
  if (ex && ui.scenario.value in ex.scenarios) ui.events.value = ex.scenarios[ui.scenario.value];
});
ui.events.addEventListener("input", () => { ui.scenario.value = "__own"; });
ui.frontend.addEventListener("change", () => compile());
ui.compile.addEventListener("click", () => compile());
ui.source.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") { e.preventDefault(); compile(); }
  if (e.key === "Tab") {
    e.preventDefault();
    ui.source.setRangeText("  ", ui.source.selectionStart, ui.source.selectionEnd, "end");
  }
});
let draftTimer = 0;
ui.source.addEventListener("input", () => {
  clearTimeout(draftTimer);
  draftTimer = setTimeout(() => {
    localStorage.setItem(DRAFT_KEY, ui.source.value);
    const draft = ui.example.querySelector('option[value="__draft"]');
    draft.hidden = false;
    ui.example.value = "__draft";
  }, 300);
});

// ------------------------------------------------------------------ компиляция

async function compile() {
  if (!compileFn) return;
  status("Компиляция…");
  await new Promise((r) => setTimeout(r, 0)); // дать браузеру перерисовать статус
  let r;
  try {
    r = JSON.parse(compileFn(ui.source.value, ui.frontend.value));
  } catch (e) {
    status("Внутренняя ошибка компилятора — см. консоль", "error");
    console.error(e);
    return;
  }
  lastResult = r;
  showDiagnostics(r.diagnostics);
  ui.wat.textContent = r.wat || "// код не сгенерирован: есть ошибки";
  ui.ast.textContent = r.ast || "// дерево не построено: синтаксическая ошибка";
  mermaidRendered = null;
  if (!document.querySelector('[data-panel="diagram"]').hidden) renderDiagram();

  const errors = r.diagnostics.filter((d) => d.level === "error").length;
  const warnings = r.diagnostics.length - errors;
  if (r.ok) {
    const bytes = Uint8Array.from(atob(r.wasm), (c) => c.charCodeAt(0));
    await loadMachine(bytes);
    if (wasmUrl) URL.revokeObjectURL(wasmUrl);
    wasmUrl = URL.createObjectURL(new Blob([bytes], { type: "application/wasm" }));
    ui.download.href = wasmUrl;
    ui.download.download = (r.meta.machine || "machine").toLowerCase() + ".wasm";
    ui.download.hidden = false;
    status(`Готово за ${r.ms} мс: ${r.stats.wasm_bytes} байт WASM`
      + (warnings ? `, предупреждений: ${warnings}` : ""), warnings ? "warn" : "ok");
  } else {
    machine = null;
    ui.download.hidden = true;
    renderMachine();
    status(`Ошибок: ${errors}` + (warnings ? `, предупреждений: ${warnings}` : ""), "error");
    showTab("diag");
  }
}

function showDiagnostics(list) {
  ui.diags.replaceChildren();
  if (!list.length) {
    const li = document.createElement("li");
    li.className = "fsm-pg__ok";
    li.textContent = "Ошибок и предупреждений нет.";
    ui.diags.append(li);
    return;
  }
  for (const d of list) {
    const li = document.createElement("li");
    li.dataset.level = d.level;
    const where = document.createElement("button");
    where.type = "button";
    where.className = "fsm-pg__where";
    where.textContent = d.line ? `${d.line}:${d.col}` : "—";
    where.addEventListener("click", () => jumpTo(d.line, d.col));
    const code = document.createElement("code");
    code.textContent = d.code;
    li.append(where, code, document.createTextNode(" " + d.message));
    ui.diags.append(li);
  }
}

function jumpTo(line, col) {
  if (!line) return;
  const lines = ui.source.value.split("\n");
  let pos = 0;
  for (let i = 0; i < line - 1 && i < lines.length; i++) pos += lines[i].length + 1;
  pos += Math.max(0, col - 1);
  ui.source.focus();
  ui.source.setSelectionRange(pos, pos + 1);
  // Прокрутить к строке: высота строки примерно одинакова.
  const lh = parseFloat(getComputedStyle(ui.source).lineHeight) || 18;
  ui.source.scrollTop = Math.max(0, (line - 5) * lh);
}

// ------------------------------------------------------------------ диаграмма

let mermaidRendered = null;
async function renderDiagram() {
  if (!lastResult || mermaidRendered === lastResult) return;
  mermaidRendered = lastResult;
  if (!lastResult.mermaid) {
    ui.diagram.textContent = "Диаграмма недоступна: программа не разобрана.";
    return;
  }
  try {
    if (!mermaidLib) {
      ui.diagram.textContent = "Загрузка Mermaid…";
      mermaidLib = (await import(MERMAID)).default;
      const dark = document.body.getAttribute("data-md-color-scheme") === "slate";
      mermaidLib.initialize({ startOnLoad: false, theme: dark ? "dark" : "neutral",
                              securityLevel: "strict" });
    }
    const { svg } = await mermaidLib.render("pg-mermaid-" + Date.now(), lastResult.mermaid);
    ui.diagram.innerHTML = svg;
  } catch (e) {
    ui.diagram.textContent = "Mermaid не смог нарисовать диаграмму:\n" + e.message
      + "\n\n" + lastResult.mermaid;
  }
}

// ------------------------------------------------------------------ запуск

async function loadMachine(bytes) {
  machine = await FsmMachine.load(bytes, { onLine: (line) => log(line, "out") });
  ui.log.textContent = "";
  renderMachine();
}

function renderMachine() {
  ui.buttons.replaceChildren();
  if (!machine) {
    ui.state.textContent = "—";
    ui.context.textContent = "";
    return;
  }
  ui.state.textContent = machine.state;
  ui.context.textContent = Object.entries(machine.context)
    .map(([k, v]) => `${k} = ${typeof v === "string" ? JSON.stringify(v) : v}`).join("   ");
  for (const ev of machine.events) {
    const form = document.createElement("form");
    form.className = "fsm-pg__event";
    const inputs = ev.params.map((p) => {
      const input = document.createElement("input");
      input.placeholder = `${p.name}: ${p.type}`;
      input.required = true;
      input.size = 8;
      if (p.type !== "string") input.inputMode = "numeric";
      return input;
    });
    const button = document.createElement("button");
    button.type = "submit";
    button.textContent = ev.name;
    form.append(button, ...inputs);
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      send(ev.name, inputs.map((i) => i.value));
    });
    ui.buttons.append(form);
  }
}

function log(text, kind) {
  const line = document.createElement("span");
  line.className = "fsm-pg__log-" + kind;
  line.textContent = text + "\n";
  ui.log.append(line);
  ui.log.scrollTop = ui.log.scrollHeight;
}

function send(name, args) {
  if (!machine) return;
  try {
    const r = machine.send(name, ...args);
    const arrow = r.status === "moved" ? `${r.from} → ${r.to}`
      : r.status === "ignored" ? `${r.from}: проигнорировано` : `${r.from}: НЕ ОБРАБОТАНО`;
    log(`› ${name}${args.length ? " " + args.join(" ") : ""}   [${arrow}]`, r.status);
  } catch (e) {
    log(`› ${name}: ${e.message}`, "unhandled");
  }
  renderMachine();
}

ui.run.addEventListener("click", () => {
  if (!machine) return;
  machine.reset();
  ui.log.textContent = "";
  for (const ev of parseScenario(ui.events.value)) send(ev.name, ev.args);
  log(`Итоговое состояние: ${machine.state}`, "final");
});
ui.reset.addEventListener("click", () => {
  if (!machine) return;
  machine.reset();
  ui.log.textContent = "";
  renderMachine();
});

boot();
