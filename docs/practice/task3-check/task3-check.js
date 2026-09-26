// Самопроверка задачи 3. Python-пакет examples/grammar-lab/grammarlab
// исполняется в Pyodide; grammarlab-bundle.zip кладёт рядом хук сборки
// сайта (tools/site_hooks.py → tools/playground_bundle.py).

// Версия — как в docs/playground/playground.js: браузер берёт Pyodide из кэша.
const PYODIDE = "https://cdn.jsdelivr.net/pyodide/v314.0.7/full/";
const DRAFT_KEY = "grammar-lab-draft-v1";
const REVEAL_AFTER = 3;  // попыток на элемент до кнопки «показать эталон»

const $ = (id) => document.getElementById(id);
const ui = {
  example: $("gl-example"), check: $("gl-check"), status: $("gl-status"),
  source: $("gl-source"), result: $("gl-result"), grid: $("gl-grid"),
  tabText: $("gl-tab-text"), tabGrid: $("gl-tab-grid"),
};

let checkFn = null;
let gridFn = null;       // grammarlab.web.grid_json
let applyFn = null;      // grammarlab.web.apply_grid_json
const attempts = loadAttempts();
const opened = new Set();   // раскрытые уровни: "<key>|2", "<key>|3", "<key>|r"

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
  ui.example.addEventListener("change", () => {
    const ex = examples.find((e) => e.id === ui.example.value);
    if (ex) { ui.source.value = ex.source; saveDraft(); opened.clear(); lastText = null; refreshGrid(); }
  });
  ui.source.value = localStorage.getItem(DRAFT_KEY) ?? (examples[0]?.source || "grammar:\n");
  ui.source.addEventListener("input", debounce(saveDraft, 300));
  ui.source.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); run(); }
  });
  ui.check.addEventListener("click", run);
  ui.tabText.addEventListener("click", () => setView("text"));
  ui.tabGrid.addEventListener("click", () => setView("grid"));

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
from grammarlab.web import check_json, grid_json, apply_grid_json
`);
    checkFn = pyodide.globals.get("check_json");
    gridFn = pyodide.globals.get("grid_json");
    applyFn = pyodide.globals.get("apply_grid_json");
    ui.check.disabled = false;
    ui.tabGrid.disabled = false;
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
  const text = ui.source.value;
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
  if (view === "grid") refreshGrid();
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
    out.push(`</ul><p class="gl__muted">Попытка не засчитана: исправьте запись.</p>`);
    ui.result.innerHTML = out.join("");
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

// ---------------------------------------------------------- табличный редактор
//
// Текст ответа — источник правды. Сетка строится из текста (grid_json), а
// каждое изменение в сетке сразу записывается в текст (apply_grid_json):
// сериализация в DSL живёт в Python, в одном месте с разбором.

let view = "text";
let model = null;        // последняя модель сетки
let gridState = null;    // {first, follow, table} в формате apply_grid

function setView(v) {
  view = v;
  ui.tabText.setAttribute("aria-selected", String(v === "text"));
  ui.tabGrid.setAttribute("aria-selected", String(v === "grid"));
  ui.source.hidden = v !== "text";
  ui.grid.hidden = v !== "grid";
  if (v === "grid") refreshGrid();
}

function refreshGrid() {
  if (!gridFn || view !== "grid") return;
  model = JSON.parse(gridFn(ui.source.value));
  if (!model.ok) {
    gridState = null;
    const errs = model.internal_error ? [{ message: model.internal_error }] : (model.errors || []);
    ui.grid.innerHTML = `<p class="gl__bad">Таблицы строятся по грамматике, а она пока не разобрана:</p>
      <ul class="gl__list">${errs.map((d) => `<li class="gl__bad">${d.line ? `строка ${d.line} — ` : ""}${esc(d.message)}</li>`).join("")}</ul>
      <p class="gl__muted">Исправьте секцию grammar на вкладке «Текст».</p>`;
    return;
  }
  gridState = { first: model.first, follow: model.follow, table: model.table };
  renderGrid();
}

// Ошибки последней проверки по ключам элементов: подсветка в сетке.
function wrongKeys() {
  const keys = new Set();
  for (const f of last?.findings || []) if (f.severity === "error") keys.add(f.key);
  return keys;
}

function renderGrid() {
  const m = model, st = gridState, wrong = wrongKeys();
  const lab = (s) => esc(m.labels[s] ?? s);
  const out = [];
  if (m.lossy.length) {
    out.push(`<details class="gl__lossy" open><summary class="gl__warn">В тексте есть записи, которых нет в таблицах (${m.lossy.length})</summary>
      <ul class="gl__list">${m.lossy.map((x) => `<li>${esc(x)}</li>`).join("")}</ul>
      <p class="gl__muted">Изменение в таблице перезапишет секцию целиком — эти записи пропадут.</p></details>`);
  }
  for (const [name, title, cols] of [["first", "FIRST", m.terminals.concat(["ε"])],
                                     ["follow", "FOLLOW", m.columns]]) {
    out.push(`<h4>${title} ${st[name] ? "" : `<span class="gl__muted">— секции нет в тексте; первая отметка её создаст</span>`}</h4>`);
    out.push(`<div class="gl__scroll"><table class="gl__tbl"><thead><tr><th scope="col"></th>` +
             cols.map((c) => `<th scope="col">${lab(c)}</th>`).join("") + `</tr></thead><tbody>`);
    for (const a of m.nonterminals) {
      const row = st[name]?.[a] || [];
      const bad = wrong.has(`${title}(${a})`) ? " gl__cell--bad" : "";
      out.push(`<tr><th scope="row" class="${bad}">${esc(a)}</th>` + cols.map((c) =>
        `<td><input type="checkbox" data-set="${name}" data-nt="${attr(a)}" data-sym="${attr(c)}"` +
        `${row.includes(c) ? " checked" : ""} aria-label="${attr(`${title}(${a}) ∋ ${m.labels[c] ?? c}`)}"></td>`).join("") + `</tr>`);
    }
    out.push(`</tbody></table></div>`);
  }
  out.push(`<h4>Таблица M ${st.table ? "" : `<span class="gl__muted">— секции нет в тексте; первое правило её создаст</span>`}</h4>`);
  out.push(`<div class="gl__scroll"><table class="gl__tbl gl__tbl--m"><thead><tr><th scope="col"></th>` +
           m.columns.map((c) => `<th scope="col">${lab(c)}</th>`).join("") + `</tr></thead><tbody>`);
  for (const a of m.nonterminals) {
    out.push(`<tr><th scope="row">${esc(a)}</th>`);
    for (const c of m.columns) {
      const chosen = st.table?.[a]?.[c] || [];
      const bad = wrong.has(m.cell_keys[a][c]) ? " gl__cell--bad" : "";
      out.push(`<td class="${bad}">` + m.alternatives[a].map((alt, i) =>
        `<label class="gl__rule"><input type="checkbox" data-cell="1" data-nt="${attr(a)}" data-sym="${attr(c)}" data-alt="${i}"` +
        `${chosen.includes(i) ? " checked" : ""}> ${esc(a)}&nbsp;→&nbsp;${esc(alt)}</label>`).join("") + `</td>`);
    }
    out.push(`</tr>`);
  }
  out.push(`</tbody></table></div>
    <p class="gl__muted">Отметьте в ячейке правило, которое туда попадает. Два отмеченных правила — конфликт.
    Красным выделены элементы с ошибками по последней проверке.</p>`);
  ui.grid.innerHTML = out.join("");
}

ui.grid.addEventListener("change", (e) => {
  const el = e.target;
  if (!gridState || el.type !== "checkbox") return;
  const a = el.dataset.nt, c = el.dataset.sym;
  if (el.dataset.set) {
    const name = el.dataset.set;
    gridState[name] ||= {};
    const row = new Set(gridState[name][a] || []);
    el.checked ? row.add(c) : row.delete(c);
    const order = name === "first" ? model.terminals.concat(["ε"]) : model.columns;
    gridState[name][a] = order.filter((x) => row.has(x));
    writeGrid({ [name]: gridState[name] });
  } else if (el.dataset.cell) {
    gridState.table ||= {};
    const row = (gridState.table[a] ||= {});
    const idx = new Set(row[c] || []);
    const i = Number(el.dataset.alt);
    el.checked ? idx.add(i) : idx.delete(i);
    row[c] = [...idx].sort((x, y) => x - y);
    writeGrid({ table: gridState.table });
  }
});

function writeGrid(part) {
  lastText = null;  // ответ изменился — следующая проверка считается попыткой
  const grid = { first: null, follow: null, table: null, ...part };
  const r = JSON.parse(applyFn(ui.source.value, JSON.stringify(grid)));
  if (!r.ok) { status("Не удалось записать таблицу в текст", "error"); return; }
  ui.source.value = r.text;
  saveDraft();
  // Модель пересобирается из текста: lossy-записи исчезли, секции появились.
  model = JSON.parse(gridFn(r.text));
  gridState = { first: model.first, follow: model.follow, table: model.table };
  if (model.lossy.length === 0) {
    const d = ui.grid.querySelector(".gl__lossy");
    if (d) d.remove();
  }
  for (const h of ui.grid.querySelectorAll("h4 .gl__muted")) {
    const t = h.parentElement.textContent;
    if ((t.startsWith("FIRST") && gridState.first) || (t.startsWith("FOLLOW") && gridState.follow) ||
        (t.startsWith("Таблица") && gridState.table)) h.remove();
  }
}

// ---------------------------------------------------------------- утилиты

function status(text, kind = "") { ui.status.textContent = text; ui.status.dataset.kind = kind; }
function esc(s) { return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c])); }
function attr(s) { return esc(s).replace(/'/g, "&#39;"); }
function debounce(fn, ms) { let t; return () => { clearTimeout(t); t = setTimeout(fn, ms); }; }
function saveDraft() { try { localStorage.setItem(DRAFT_KEY, ui.source.value); } catch { /* приватный режим */ } }
function loadAttempts() { try { return JSON.parse(localStorage.getItem(DRAFT_KEY + ":attempts")) || {}; } catch { return {}; } }
function saveAttempts() { try { localStorage.setItem(DRAFT_KEY + ":attempts", JSON.stringify(attempts)); } catch { /* */ } }

boot();
