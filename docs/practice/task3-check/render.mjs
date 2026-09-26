// Текст секций first/follow/table из состояния таблицы.
//
// Зеркало grid._render (examples/grammar-lab/grammarlab/grid.py): метки
// символов и правил, порядок элементов берутся из модели, которую строит
// Python, поэтому здесь только склейка строк. Совпадение с Python
// проверяет tools/pyodide-smoke/smoke.mjs.

// sets: {A: [символ, …]} — символы во внутренней записи (ε, $, ';' без кавычек).
export function renderSet(name, sets, model) {
  const rank = new Map(model.set_order.map((s, i) => [s, i]));
  const lines = [`${name}:`];
  for (const a of model.nonterminals) {
    if (!sets || !(a in sets)) continue;
    const vals = [...sets[a]].sort((x, y) => rank.get(x) - rank.get(y));
    lines.push(`  ${a} = { ${vals.map((v) => model.labels[v]).join(", ")} }`);
  }
  return lines.join("\n");
}

// table: {A: {t: [номер альтернативы, …]}}
export function renderTable(table, model) {
  const lines = ["table:"];
  for (const a of model.nonterminals) {
    const row = table?.[a] || {};
    for (const t of model.columns) {
      const idx = row[t] || [];
      if (idx.length) {
        lines.push(`  ${model.cell_keys[a][t]} = ` + idx.map((i) => model.rules[a][i]).join(" ;; "));
      }
    }
  }
  return lines.join("\n");
}

// Текст для заголовка «trace "…":» по строкам трассы [{stack, rest, action}].
export function renderTrace(word, rows) {
  const w1 = Math.max(0, ...rows.map((r) => r.stack.length));
  const w2 = Math.max(0, ...rows.map((r) => r.rest.length));
  return [`trace "${word}":`, ...rows.map((r) =>
    `  ${r.stack.padEnd(w1)} | ${r.rest.padEnd(w2)} | ${r.action}`)].join("\n");
}
