// Самопроверка задачи 3. Python-пакет examples/grammar-lab/grammarlab
// исполняется в Pyodide; grammarlab-bundle.zip кладёт рядом хук сборки
// сайта (tools/site_hooks.py → tools/playground_bundle.py).
// Редактор — CodeMirror 6 (editor.mjs, codemirror.mjs собран
// tools/codemirror-bundle).

import { createEditor } from "./editor.mjs";

// Версия — как в docs/playground/playground.js: браузер берёт Pyodide из кэша.
const PYODIDE = "https://cdn.jsdelivr.net/pyodide/v314.0.7/full/";
const DRAFT_KEY = "grammar-lab-draft-v1";
const REVEAL_AFTER = 3;  // попыток на элемент до подсказки у кнопки «показать эталон»

const $ = (id) => document.getElementById(id);
const ui = {
  example: $("gl-example"), check: $("gl-check"), status: $("gl-status"),
  result: $("gl-result"), host: $("gl-editor"),
};

let checkFn = null;
let layoutFn = null;
let editor = null;
const attempts = loadAttempts();
const opened = new Set();   // раскрытые уровни: "step|<шаг>", "<key>|3", "<key>|r"

// -------------------------------------------------------------- загрузка

async function boot() {
  let examples = [];
  try {
    examples = await (await fetch("examples.json")).json();
  } catch { /* примеров нет — не страшно */ }
  for (const ex of examples) {
    const opt = document.createElement("option");
    opt.value = ex.id;
    opt.textContent = ex.title;
    ui.example.append(opt);
  }
  let initial;
  try { initial = localStorage.getItem(DRAFT_KEY); } catch { initial = null; }
  editor = createEditor(ui.host, initial ?? (examples[0]?.source || "grammar:\n"), {
    layout: (text) => (layoutFn ? JSON.parse(layoutFn(text)) : null),
    onChange: debounce(saveDraft, 300),
    onRun: run,
  });
  window.glEditor = editor;   // для автотестов страницы
  ui.example.addEventListener("change", () => {
    const ex = examples.find((e) => e.id === ui.example.value);
    if (!ex) return;
    editor.setText(ex.source);
    saveDraft();
    opened.clear();
    last = null;
    lastText = null;
    ui.result.innerHTML = `<p class="gl__muted">Нажмите «Проверить».</p>`;
    editor.setMarks([]);
  });
  ui.check.addEventListener("click", run);
  // Черновик сохраняется с задержкой — при уходе со страницы дописать сразу.
  addEventListener("pagehide", () => saveDraft());

  try {
    status("Загрузка Pyodide (около 6 МБ при первом открытии)…");
    const { loadPyodide } = await import(PYODIDE + "pyodide.mjs");
    const pyodide = await loadPyodide({ indexURL: PYODIDE });
    status("Загрузка проверки…");
    const bundle = await (await fetch("grammarlab-bundle.zip")).arrayBuffer();
    pyodide.unpackArchive(bundle, "zip", { extractDir: "/home/pyodide/grammarlab-lib" });
    pyodide.runPython(`
import sys
sys.path.insert(0, "/home/pyodide/grammarlab-lib")
from grammarlab.web import check_json, layout_json
`);
    checkFn = pyodide.globals.get("check_json");
    layoutFn = pyodide.globals.get("layout_json");
    editor.refresh();
    ui.check.disabled = false;
    status("Готово", "ok");
  } catch (e) {
    status("Не удалось загрузить проверку: " + e.message +
           ". Проверьте доступ к cdn.jsdelivr.net или используйте python -m grammarlab.", "error");
    console.error(e);
  }
}

// -------------------------------------------------------------- проверка

let last = null;
let lastText = null;

function run() {
  if (!checkFn) return;
  saveDraft();
  const text = editor.getText();
  const t0 = performance.now();
  last = JSON.parse(checkFn(text));
  // Попытка — это новая версия ответа, а не повторное нажатие; считаем только ошибки.
  if (text !== lastText) {
    for (const f of last.findings || []) {
      if (f.severity === "error") attempts[f.key] = (attempts[f.key] || 0) + 1;
    }
    saveAttempts();
  }
  lastText = text;
  render(last);
  status(`Проверено за ${Math.round(performance.now() - t0)} мс`, "ok");
}

const STEP_ORDER = ["grammar", "first", "follow", "table", "conflicts", "trace"];

function render(r) {
  const out = [];
  if (r.internal_error) {
    out.push(`<p class="gl__bad">Внутренняя ошибка проверки: ${esc(r.internal_error)}</p>`);
  }
  const errors = (r.parse || []).filter((d) => d.level === "error");
  const warns = (r.parse || []).filter((d) => d.level !== "error");
  if (errors.length) {
    out.push(`<h4>Запись не разобрана</h4><ul class="gl__list">`);
    for (const d of r.parse) out.push(`<li class="${d.level === "error" ? "gl__bad" : "gl__warn"}">` +
      `${d.line ? `строка ${d.line}${d.col ? `:${d.col}` : ""} — ` : ""}${esc(d.message)}</li>`);
    out.push(`</ul><p class="gl__muted">Ошибки подчёркнуты в редакторе. Попытка не засчитана.</p>`);
    ui.result.innerHTML = out.join("");
    editor.setMarks([]);
    return;
  }
  out.push(`<p class="gl__verdict ${r.findings.some((f) => f.severity === "error") ? "gl__bad" : "gl__good"}">${esc(r.verdict)}</p>`);
  if (warns.length) {
    out.push(`<ul class="gl__list">` + warns.map((d) =>
      `<li class="gl__warn">строка ${d.line} — ${esc(d.message)}</li>`).join("") + `</ul>`);
  }
  if (r.interpretation?.length) {
    out.push(`<details class="gl__interp"><summary>Как понят ваш ответ</summary><pre>${esc(r.interpretation.join("\n"))}</pre></details>`);
  }
  const by = {};
  for (const f of r.findings) (by[f.step] ||= []).push(f);
  for (const step of STEP_ORDER.filter((s) => r.checked.includes(s))) {
    const items = by[step] || [];
    const nErr = items.filter((f) => f.severity === "error").length;
    const nWarn = items.length - nErr;
    const label = !items.length ? "ok" :
      [nErr && `ошибок: ${nErr}`, nWarn && `замечаний: ${nWarn}`].filter(Boolean).join(", ");
    const cls = nErr ? "gl__bad" : nWarn ? "gl__warn" : "gl__good";
    out.push(`<section class="gl__step"><h4>${esc(r.steps[step])} <span class="${cls}">${label}</span></h4>`);
    if (items.length) {
      const key = `step|${step}`;
      if (!opened.has(key)) {
        out.push(`<button type="button" data-open="${attr(key)}">Где?</button>`);
      } else {
        out.push(`<ul class="gl__list">`);
        for (const f of items) out.push(renderFinding(f));
        out.push(`</ul>`);
      }
    }
    out.push(`</section>`);
  }
  ui.result.innerHTML = out.join("");
  // В таблицах подсвечиваются только ошибки шагов, для которых раскрыто «Где?»:
  // иначе подсветка сразу выдала бы уровень 2 подсказки.
  editor.setMarks(r.findings.filter((f) => f.severity === "error" && opened.has(`step|${f.step}`))
                            .map((f) => f.key));
}

function renderFinding(f) {
  const k = f.key;
  const parts = [`<li class="${f.severity === "error" ? "gl__bad" : "gl__warn"}">${esc(f.summary)}` +
                 (f.line ? ` <span class="gl__muted">(строка ${f.line})</span>` : "")];
  if (f.why) {
    parts.push(opened.has(k + "|3")
      ? `<div class="gl__why">${esc(f.why).replace(/\n/g, "<br>")}</div>`
      : ` <button type="button" data-open="${attr(k + "|3")}">Почему?</button>`);
  }
  if (f.reveal) {
    const n = attempts[k] || 0;
    if (opened.has(k + "|r")) {
      parts.push(`<div class="gl__reveal">${esc(f.reveal)}</div>`);
    } else {
      const hint = n < REVEAL_AFTER ? ` title="Попыток по этому элементу: ${n}. Попробуйте ещё раз сами."` : "";
      parts.push(` <button type="button" class="gl__reveal-btn" data-open="${attr(k + "|r")}"${hint}>Показать эталон</button>`);
    }
  }
  parts.push("</li>");
  return parts.join("");
}

ui.result.addEventListener("click", (e) => {
  const key = e.target?.dataset?.open;
  if (!key) return;
  opened.add(key);
  if (last) render(last);
});

// ---------------------------------------------------------------- утилиты

function status(text, kind = "") { ui.status.textContent = text; ui.status.dataset.kind = kind; }
function esc(s) { return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c])); }
function attr(s) { return esc(s).replace(/'/g, "&#39;"); }
function debounce(fn, ms) { let t; return () => { clearTimeout(t); t = setTimeout(fn, ms); }; }
function saveDraft() { try { localStorage.setItem(DRAFT_KEY, editor.getText()); } catch { /* приватный режим */ } }
function loadAttempts() { try { return JSON.parse(localStorage.getItem(DRAFT_KEY + ":attempts")) || {}; } catch { return {}; } }
function saveAttempts() { try { localStorage.setItem(DRAFT_KEY + ":attempts", JSON.stringify(attempts)); } catch { /* */ } }

boot();
