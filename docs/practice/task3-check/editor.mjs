// Редактор ответа: CodeMirror 6 с подсветкой языка ответа, ошибками разбора
// из Python и таблицами внутри текста.
//
// Текст — источник правды. Секции first/follow/table и трассы показываются
// таблицами прямо в тексте (Decoration.replace с блочным виджетом); правка
// в таблице переписывает текст секции. Если курсор внутри секции, в ней
// разобранная ошибка или записи, которых таблица не выразит, — показывается
// исходный текст. Разбор (layout) делает Python: здесь только отображение.

import {
  EditorState, StateField, StateEffect, EditorView, Decoration, WidgetType, keymap,
  lineNumbers, highlightActiveLine, highlightActiveLineGutter, drawSelection,
  defaultKeymap, history, historyKeymap, indentWithTab, StreamLanguage, HighlightStyle,
  syntaxHighlighting, setDiagnostics, lintGutter, lintKeymap, autocompletion,
  completionKeymap, tags as t,
} from "./codemirror.mjs";
import { renderSet, renderTable, renderTrace } from "./render.mjs";

// ------------------------------------------------------------- подсветка

const dsl = StreamLanguage.define({
  name: "grammarlab",
  startState: () => ({}),
  token(s) {
    if (s.eatSpace()) return null;
    if (s.match(/#.*/)) return "comment";
    if (s.sol() && s.match(/(grammar|first|follow|table|conflicts|version)(?=\s*:)/)) return "heading";
    if (s.sol() && s.match(/trace(?=\s+")/)) return "heading";
    if (s.sol() && s.match(/choose\b/)) return "keyword";
    if (s.match(/"[^"\n]*"/)) return "string";
    if (s.match(/'[^'\s]+'/)) return "string";
    if (s.match(/->|→|;;|\|/)) return "operator";
    if (s.match(/(eps|ε)(?![\w'])/)) return "atom";
    if (s.match(/(match|accept|error)(?![\w'])/)) return "keyword";
    if (s.match(/\$/)) return "atom";
    if (s.match(/M(?=\[)/)) return "keyword";
    if (s.match(/[{}[\],=:]/)) return "punctuation";
    if (s.match(/[A-ZА-ЯЁ][\wА-Яа-яЁё']*/)) return "typeName";
    if (s.match(/[a-zа-яё_0-9][\wА-Яа-яЁё']*/)) return "variableName";
    s.next();
    return "invalid";
  },
});

const style = HighlightStyle.define([
  { tag: t.heading, color: "var(--gl-c-head)", fontWeight: "700" },
  { tag: t.keyword, color: "var(--gl-c-kw)" },
  { tag: t.typeName, color: "var(--gl-c-nt)" },
  { tag: t.variableName, color: "var(--gl-c-term)" },
  { tag: t.string, color: "var(--gl-c-term)", fontWeight: "600" },
  { tag: t.atom, color: "var(--gl-c-atom)" },
  { tag: t.operator, color: "var(--gl-c-op)" },
  { tag: t.comment, color: "var(--gl-c-comment)", fontStyle: "italic" },
  { tag: t.invalid, color: "var(--gl-c-bad)", textDecoration: "underline wavy" },
]);

// ------------------------------------------------------ состояние таблиц

const editors = new WeakMap();   // view → api (replaceSection вызывает refresh)

// layout из Python; raw — позиции заголовков секций, показанных текстом
// (кнопка «текст»), перемещаются вместе с текстом при правках.
const setLayout = StateEffect.define();
const setMarks = StateEffect.define();      // ключи элементов с ошибками по проверке
const toggleRaw = StateEffect.define();     // {pos, raw}

const layoutField = StateField.define({
  create: () => ({ layout: null, marks: new Set(), raw: [], stale: false }),
  update(v, tr) {
    let next = v;
    if (tr.docChanged && next.raw.length) {
      next = { ...next, raw: next.raw.map((p) => tr.changes.mapPos(p, -1)) };
    }
    let fresh = false;
    for (const e of tr.effects) {
      if (e.is(setLayout)) { next = { ...next, layout: e.value }; fresh = true; }
      if (e.is(setMarks)) next = { ...next, marks: e.value };
      if (e.is(toggleRaw)) {
        const raw = next.raw.filter((p) => p !== e.value.pos);
        if (e.value.raw) raw.push(e.value.pos);
        next = { ...next, raw };
      }
    }
    // Текст изменился — номера строк в layout устарели до следующего layout.
    if (fresh) next = { ...next, stale: false };
    else if (tr.docChanged && next.layout) next = { ...next, stale: true };
    return next;
  },
});

const TABLE_SECTIONS = new Set(["first", "follow", "table", "trace"]);

function sectionState(lay, sec) {
  const g = lay.grid;
  if (!lay.ok || !g?.ok) return { ok: false, why: "ответ не разобран" };
  if (sec.name === "trace") {
    const tr = lay.traces.find((x) => x.line === sec.start);
    return tr ? { ok: true, trace: tr } : { ok: false, why: "трасса не разобрана" };
  }
  if ((g.lossy_by_section?.[sec.name] || []).length) {
    return { ok: false, why: "в секции есть записи, которых нет в таблице" };
  }
  if (sec.comments) return { ok: false, why: "в секции есть комментарии — таблица бы их стёрла" };
  return { ok: true };
}

const decorations = StateField.define({
  create: () => Decoration.none,
  update(deco, tr) {
    const st = tr.state.field(layoutField);
    const lay = st.layout;
    const sel = tr.state.selection.main;
    if (!lay || st.stale) {
      // Разметка устарела (идёт набор): старые таблицы просто сдвигаются с
      // текстом, но таблица, в которую попал курсор, сразу раскрывается.
      const mapped = tr.docChanged ? deco.map(tr.changes) : deco;
      return mapped.update({ filter: (from, to) => !(sel.head >= from && sel.head <= to) });
    }
    const doc = tr.state.doc;
    const ranges = [];
    const seen = new Set();
    for (const sec of lay.sections) {
      if (!TABLE_SECTIONS.has(sec.name) || sec.end > doc.lines) continue;
      const key = sec.name === "trace" ? `trace:${sec.start}` : sec.name;
      if (seen.has(key)) continue;
      seen.add(key);
      const from = doc.line(sec.start).from, to = doc.line(sec.end).to;
      if (st.raw.includes(from)) continue;
      // Курсор внутри секции (набор текста или стрелками) — показываем текст.
      // Граница `from` включена: стрелка вниз со строки выше ставит курсор
      // в начало заголовка, и секция раскрывается, а не перескакивается.
      if (sel.head >= from && sel.head <= to) continue;
      const s = sectionState(lay, sec);
      if (!s.ok) continue;
      ranges.push(Decoration.replace({
        widget: new SectionWidget(sec, lay, s, st.marks),
        block: true,
      }).range(from, to));
    }
    return Decoration.set(ranges, true);
  },
  provide: (f) => EditorView.decorations.from(f),
});

// ------------------------------------------------------------ виджет

class SectionWidget extends WidgetType {
  constructor(sec, lay, s, marks) {
    super();
    this.sec = sec; this.lay = lay; this.s = s; this.marks = marks;
    // Всё, от чего зависит DOM таблицы: модель (строки, столбцы, правила),
    // содержимое секции и подсветка ошибок.
    const g = lay.grid;
    this.sig = JSON.stringify([sec.name, sec.word, sec.end - sec.start, s.trace,
      sec.name === "trace" ? null : [g.nonterminals, g.columns, g.labels, g.rules, g[sec.name]],
      [...marks].sort()]);
  }
  eq(other) { return other.sig === this.sig; }
  ignoreEvent() { return true; }   // клики и ввод внутри таблицы — не текстовые
  get estimatedHeight() { return 24 * (this.sec.end - this.sec.start + 2); }

  toDOM(view) {
    const box = document.createElement("div");
    box.className = "gl-w";
    box.dataset.section = this.sec.name;
    const head = document.createElement("div");
    head.className = "gl-w__head";
    const title = document.createElement("span");
    title.className = "gl-w__title";
    title.textContent = this.sec.name === "trace" ? `trace "${this.sec.word}"` : this.sec.name;
    const raw = button("текст", "Показать эту секцию текстом", () => {
      const r = widgetRange(view, box);
      if (r) view.dispatch({ effects: toggleRaw.of({ pos: r.from, raw: true }) });
    });
    head.append(title, raw);
    box.append(head);
    const body = document.createElement("div");
    body.className = "gl-w__scroll";
    const edit = (text, focusKey) => replaceSection(view, box, text, focusKey);
    if (this.sec.name === "trace") body.append(traceTable(edit, this.sec, this.s.trace));
    else if (this.sec.name === "table") body.append(mTable(edit, this.sec, this.lay.grid, this.marks));
    else body.append(setTable(edit, this.sec, this.lay.grid, this.marks));
    box.append(body);
    return box;
  }
}

function button(text, title, onClick) {
  const b = document.createElement("button");
  b.type = "button";
  b.textContent = text;
  b.title = title;
  b.addEventListener("click", (e) => { e.preventDefault(); onClick(); });
  return b;
}

// Текущий диапазон таблицы в документе — по самой декорации, а не по номерам
// строк из layout: те устаревают, пока пользователь набирает текст.
function widgetRange(view, dom) {
  const pos = view.posAtDOM(dom);
  let found = null;
  view.state.field(decorations).between(pos, pos, (from, to) => {
    if (from === pos) found = { from, to };
  });
  return found;
}

// Правка из таблицы: заменить текст секции. focusKey — data-focus элемента,
// которому вернуть фокус в перестроенной таблице (клавиатурная работа).
function replaceSection(view, dom, text, focusKey) {
  const ed = editors.get(view);
  // Диапазон берётся ДО обновления разметки: refresh пересоздаёт декорации,
  // и таблица, по которой кликнули, может смениться новой (с другим DOM).
  const r = widgetRange(view, dom);
  if (!r) return;           // таблица уже раскрыта или исчезла — правку не применяем
  if (view.state.sliceDoc(r.from, r.to) === text) return;
  view.dispatch({ changes: { from: r.from, to: r.to, insert: text }, userEvent: "input.table" });
  ed?.refresh();            // сразу: следующая правка должна видеть новые строки
  if (focusKey) {
    requestAnimationFrame(() => {
      const target = view.dom.querySelector(`[data-focus="${CSS.escape(focusKey)}"]`);
      if (target) target.focus();
    });
  }
}


function el(tag, attrs = {}, text) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v; else e.setAttribute(k, v);
  }
  if (text !== undefined) e.textContent = text;
  return e;
}

function setTable(edit, sec, g, marks) {
  const name = sec.name, title = name.toUpperCase();
  const cols = name === "first" ? g.terminals.concat(["ε"]) : g.columns;
  const state = structuredClone(g[name] || {});
  const tbl = el("table", { class: "gl-w__tbl" });
  const hr = el("tr");
  hr.append(el("th"));
  for (const c of cols) hr.append(el("th", { scope: "col" }, g.labels[c]));
  const thead = el("thead"); thead.append(hr); tbl.append(thead);
  const tb = el("tbody");
  for (const a of g.nonterminals) {
    const tr = el("tr");
    const th = el("th", { scope: "row" }, a);
    if (marks.has(`${title}(${a})`)) th.classList.add("gl-w--bad");
    tr.append(th);
    for (const c of cols) {
      const td = el("td");
      const key = `${name}|${a}|${c}`;
      const cb = el("input", { type: "checkbox", "aria-label": `${title}(${a}) ∋ ${g.labels[c]}`,
                              "data-nt": a, "data-sym": c, "data-focus": key });
      cb.checked = (state[a] || []).includes(c);
      cb.addEventListener("change", () => {
        const row = new Set(state[a] || []);
        cb.checked ? row.add(c) : row.delete(c);
        state[a] = [...row];
        edit(renderSet(name, state, g), key);
      });
      td.append(cb);
      tr.append(td);
    }
    tb.append(tr);
  }
  tbl.append(tb);
  return tbl;
}

function mTable(edit, sec, g, marks) {
  const state = structuredClone(g.table || {});
  const tbl = el("table", { class: "gl-w__tbl gl-w__tbl--m" });
  const hr = el("tr");
  hr.append(el("th"));
  for (const c of g.columns) hr.append(el("th", { scope: "col" }, g.labels[c]));
  const thead = el("thead"); thead.append(hr); tbl.append(thead);
  const tb = el("tbody");
  for (const a of g.nonterminals) {
    const tr = el("tr");
    tr.append(el("th", { scope: "row" }, a));
    for (const c of g.columns) {
      const td = el("td");
      if (marks.has(g.cell_keys[a][c])) td.classList.add("gl-w--bad");
      g.rules[a].forEach((rule, i) => {
        const lab = el("label", { class: "gl-w__rule" });
        const key = `table|${a}|${c}|${i}`;
        const cb = el("input", { type: "checkbox", "data-nt": a, "data-sym": c, "data-alt": String(i),
                                "data-focus": key, "aria-label": `M[${a}, ${g.labels[c]}] = ${rule}` });
        cb.checked = (state[a]?.[c] || []).includes(i);
        cb.addEventListener("change", () => {
          const row = (state[a] ||= {});
          const idx = new Set(row[c] || []);
          cb.checked ? idx.add(i) : idx.delete(i);
          row[c] = [...idx].sort((x, y) => x - y);
          edit(renderTable(state, g), key);
        });
        lab.append(cb, document.createTextNode(" " + rule.replace(" -> ", " → ")));
        td.append(lab);
      });
      tr.append(td);
    }
    tb.append(tr);
  }
  tbl.append(tb);
  return tbl;
}

// Трасса: ячейки — поля ввода. Текст секции переписывается, когда фокус
// покидает таблицу (или по Enter), а не на каждый переход между ячейками:
// иначе перестройка таблицы посреди Tab уничтожает поле, в которое
// переходит пользователь. Пустые строки в текст не пишутся, пока не заполнены.
function traceTable(edit, sec, tr) {
  const rows = tr.rows.map((r) => ({ stack: r.stack.join(" "), rest: r.rest.join(" "), action: r.action }));
  const wrap = el("div");
  const tbl = el("table", { class: "gl-w__tbl gl-w__tbl--trace" });
  const hr = el("tr");
  for (const h of ["", "стек", "вход", "действие", ""]) hr.append(el("th", { scope: "col" }, h));
  const thead = el("thead"); thead.append(hr); tbl.append(thead);
  const tb = el("tbody");
  tbl.append(tb);
  let dirty = false;
  const filled = () => rows.filter((r) => r.stack || r.rest || r.action);
  const commit = (focusKey) => {
    if (!dirty) return;
    dirty = false;
    edit(renderTrace(sec.word, filled()), focusKey);
  };
  const draw = (focusKey) => {
    tb.replaceChildren();
    rows.forEach((r, i) => {
      const row = el("tr");
      row.append(el("th", { scope: "row" }, String(i + 1)));
      for (const k of ["stack", "rest", "action"]) {
        const td = el("td");
        // Tab в поле выделяет его содержимое, как в электронных таблицах:
        // набор заменяет ячейку целиком, End — дописать в конец.
        const inp = el("input", { type: "text", value: r[k], spellcheck: "false",
                                 "aria-label": `строка ${i + 1}, ${{ stack: "стек", rest: "вход", action: "действие" }[k]}`,
                                 class: `gl-w__in gl-w__in--${k}`, "data-focus": `trace|${i}|${k}` });
        inp.addEventListener("input", () => { r[k] = inp.value.trim(); dirty = true; });
        inp.addEventListener("focus", () => inp.select());
        inp.addEventListener("keydown", (e) => {
          if (e.key === "Enter") { e.preventDefault(); commit(`trace|${i}|${k}`); }
        });
        td.append(inp);
        row.append(td);
      }
      const ops = el("td", { class: "gl-w__ops" });
      ops.append(
        button("+", "Вставить копию строки ниже", () => {
          rows.splice(i + 1, 0, { ...r }); dirty = true; commit(`trace|${i + 1}|action`);
        }),
        button("−", "Удалить строку", () => {
          rows.splice(i, 1); dirty = true; commit(`trace|${Math.max(0, i - 1)}|action`);
        }),
      );
      row.append(ops);
      tb.append(row);
    });
    if (focusKey) wrap.querySelector(`[data-focus="${CSS.escape(focusKey)}"]`)?.focus();
  };
  draw();
  // Фокус ушёл из таблицы — записать изменения в текст.
  wrap.addEventListener("focusout", (e) => {
    if (!wrap.contains(e.relatedTarget)) queueMicrotask(() => commit());
  });
  const add = el("div", { class: "gl-w__foot" });
  add.append(button("+ строка", "Добавить пустую строку в конец (попадёт в текст, когда её заполните)", () => {
    rows.push({ stack: "", rest: "", action: "" });
    draw(`trace|${rows.length - 1}|stack`);
  }));
  wrap.append(tbl, add);
  return wrap;
}

// ------------------------------------------------------ автодополнение

function complete(ctx) {
  const lay = ctx.state.field(layoutField).layout;
  const word = ctx.matchBefore(/[\wА-Яа-яЁё']+/);
  if (!word && !ctx.explicit) return null;
  const options = [];
  for (const nt of lay?.nonterminals || []) options.push({ label: nt, type: "type", detail: "нетерминал" });
  for (const tm of lay?.terminals || []) options.push({ label: tm, type: "variable", detail: "терминал" });
  for (const kw of ["eps", "match", "accept", "error"]) options.push({ label: kw, type: "keyword" });
  const line = ctx.state.doc.lineAt(ctx.pos);
  if (!line.text.slice(0, ctx.pos - line.from).trim()) {
    for (const s of ["grammar:", "first:", "follow:", "table:", "conflicts:", 'trace "":']) {
      options.push({ label: s, type: "keyword", detail: "секция" });
    }
  }
  return { from: word ? word.from : ctx.pos, options, validFor: /^[\wА-Яа-яЁё']*$/ };
}

// ------------------------------------------------------------- тема

const theme = EditorView.theme({
  "&": { height: "100%", fontSize: ".72rem", backgroundColor: "var(--md-code-bg-color)" },
  ".cm-scroller": { fontFamily: "var(--md-code-font)", lineHeight: "1.55" },
  ".cm-content": { caretColor: "var(--md-default-fg-color)" },
  ".cm-gutters": { backgroundColor: "var(--md-code-bg-color)", border: "none", color: "var(--course-muted)" },
  ".cm-activeLine, .cm-activeLineGutter": { backgroundColor: "rgba(127,127,127,.08)" },
  ".cm-tooltip": { fontSize: ".7rem" },
});

// ------------------------------------------------------------ фабрика

// hooks.layout(text) → объект layout из Python (синхронно);
// hooks.onChange(text) — после каждого изменения (сохранение черновика);
// hooks.onRun() — Ctrl+Enter.
export function createEditor(parent, text, hooks) {
  let timer = null;
  const view = new EditorView({
    parent,
    state: EditorState.create({
      doc: text,
      extensions: [
        lineNumbers(), highlightActiveLineGutter(), highlightActiveLine(), drawSelection(),
        history(), dsl, syntaxHighlighting(style), lintGutter(),
        autocompletion({ override: [complete], activateOnTyping: true }),
        layoutField, decorations, theme, EditorView.lineWrapping,
        EditorView.contentAttributes.of({ "aria-label": "Ответ", spellcheck: "false" }),
        keymap.of([
          { key: "Mod-Enter", run: () => { hooks.onRun?.(); return true; } },
          { key: "ArrowDown", run: (v) => moveLine(v, 1) },
          { key: "ArrowUp", run: (v) => moveLine(v, -1) },
          indentWithTab, ...completionKeymap, ...lintKeymap, ...historyKeymap, ...defaultKeymap,
        ]),
        EditorView.updateListener.of((u) => {
          if (!u.docChanged) return;   // выделение: decorations.update сам учтёт курсор
          hooks.onChange?.(u.state.doc.toString());
          clearTimeout(timer);
          // Правку из таблицы уже разметил replaceSection; набор — после паузы.
          if (u.transactions.some((tr) => tr.isUserEvent("input.table"))) return;
          timer = setTimeout(() => refresh(), 400);
        }),
      ],
    }),
  });

  function refresh() {
    if (!hooks.layout) return;
    const lay = hooks.layout(view.state.doc.toString());
    if (!lay) return;         // Python ещё загружается
    const doc = view.state.doc;
    const diags = (lay.diagnostics || []).map((d) => {
      const ln = doc.line(Math.max(1, Math.min(d.line || 1, doc.lines)));
      const from = Math.min(ln.to, ln.from + Math.max(0, (d.col || 1) - 1));
      const m = /^[^\s|]+/.exec(ln.text.slice(from - ln.from));
      return {
        from, to: Math.min(ln.to, from + (m ? m[0].length : 1)) || from,
        severity: d.level === "warning" ? "warning" : "error",
        source: d.code, message: d.message,
      };
    });
    if (lay.internal_error) diags.push({ from: 0, to: 0, severity: "error", message: lay.internal_error });
    view.dispatch(setDiagnostics(view.state, diags), { effects: setLayout.of(lay) });
  }

  const api = {
    view,
    getText: () => view.state.doc.toString(),
    setText(t) {
      view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: t },
                      effects: toggleRawReset(view) });
      refresh();
    },
    flush: () => hooks.onChange?.(view.state.doc.toString()),
    refresh,
    setMarks(keys) { view.dispatch({ effects: setMarks.of(new Set(keys)) }); },
    showRaw(line, raw = true) {
      view.dispatch({ effects: toggleRaw.of({ pos: view.state.doc.line(line).from, raw }) });
    },
    // Для тестов: какие секции сейчас показаны таблицами (по декорациям,
    // а не по DOM: CodeMirror рисует только видимую часть документа).
    tables() {
      const out = [];
      view.state.field(decorations).between(0, view.state.doc.length, (from, to, d) => {
        out.push(d.spec.widget.sec.name);
      });
      return out;
    },
    // Прокрутить к секции, чтобы её таблица попала в DOM.
    reveal(name, n = 0) {
      const secs = (view.state.field(layoutField).layout?.sections || []).filter((s) => s.name === name);
      const sec = secs[n];
      if (!sec) return false;
      const pos = view.state.doc.line(sec.start).from;
      view.dispatch({ effects: EditorView.scrollIntoView(pos, { y: "start" }) });
      return true;
    },
  };
  editors.set(view, api);
  return api;
}

// Стрелки вверх/вниз — строго на соседнюю строку документа. Штатное
// движение CodeMirror идёт по экранным строкам и перескакивает блочный
// виджет целиком (в таблицу стрелками не попасть) или, наоборот, прыгает через
// строки, когда таблица раскрывается на ходу. Здесь курсор входит в секцию
// построчно — и секция раскрывается в текст. Перенос длинных строк
// (lineWrapping) обрабатывается штатно: если соседняя экранная строка — часть
// той же строки документа, отдаём ход CodeMirror.
function moveLine(view, dir) {
  const sel = view.state.selection.main;
  if (!sel.empty) return false;
  const doc = view.state.doc;
  const line = doc.lineAt(sel.head);
  const n = line.number + dir;
  if (n < 1 || n > doc.lines) return false;
  const screen = view.moveVertically(sel, dir > 0);
  if (doc.lineAt(screen.head).number === line.number) return false;   // перенос строки
  const target = doc.line(n);
  const col = Math.min(sel.head - line.from, target.length);
  view.dispatch({ selection: { anchor: target.from + col }, scrollIntoView: true, userEvent: "select" });
  return true;
}

function toggleRawReset(view) {
  return view.state.field(layoutField).raw.map((pos) => toggleRaw.of({ pos, raw: false }));
}
