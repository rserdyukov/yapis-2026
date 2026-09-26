// Smoke-тест Python-бандлов сайта в настоящем Pyodide (той же версии, что
// на страницах). Запускается в CI после `mkdocs build`:
//
//   cd tools/pyodide-smoke && npm ci && node smoke.mjs ../../site
//
// Проверяет, что бандлы распаковываются, импортируются и дают ожидаемый
// результат на эталонном примере (Python 3.14 в Pyodide против 3.12 в CI).

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { loadPyodide } from "pyodide";

const site = process.argv[2] || "../../site";
const pyodide = await loadPyodide();
let failed = 0;

function load(zip, dir) {
  // Buffer из readFileSync Pyodide не принимает — нужен Uint8Array.
  pyodide.unpackArchive(new Uint8Array(readFileSync(zip)), "zip", { extractDir: dir });
  pyodide.runPython(`import sys; sys.path.insert(0, ${JSON.stringify(dir)})`);
}

function check(name, cond, detail = "") {
  console.log(`${cond ? "ok  " : "FAIL"} ${name}${detail ? " — " + detail : ""}`);
  if (!cond) failed++;
}

// ---- самопроверка задачи 3
const gl = join(site, "practice/task3-check");
if (!existsSync(join(gl, "index.html"))) {
  console.log("skip grammarlab: страница не опубликована");
} else if (existsSync(join(gl, "grammarlab-bundle.zip"))) {
  load(join(gl, "grammarlab-bundle.zip"), "/home/pyodide/gl");
  const checkJson = pyodide.runPython("from grammarlab.web import check_json; check_json");
  const examples = JSON.parse(readFileSync(join(gl, "examples.json"), "utf-8"));
  check("grammarlab: примеры есть", examples.length >= 3, `${examples.length}`);
  for (const ex of examples) {
    const r = JSON.parse(checkJson(ex.source));
    check(`grammarlab: ${ex.id} без ошибок`, r.ok && r.findings.length === 0 && !r.internal_error, r.verdict || r.internal_error);
  }
  const bad = JSON.parse(checkJson(examples[0].source.replace("N = { b, $ }", "N = { $ }")));
  check("grammarlab: мутант FOLLOW(N) найден",
        bad.findings.length === 1 && bad.findings[0].key === "FOLLOW(N)" && bad.findings[0].why.includes("⇒"));
  const gridJson = pyodide.runPython("from grammarlab.web import grid_json; grid_json");
  const applyJson = pyodide.runPython("from grammarlab.web import apply_grid_json; apply_grid_json");
  const m = JSON.parse(gridJson(examples[0].source));
  const back = JSON.parse(applyJson(examples[0].source,
    JSON.stringify({ first: m.first, follow: m.follow, table: m.table })));
  const again = JSON.parse(checkJson(back.text));
  check("grammarlab: табличный редактор — туда и обратно", m.ok && back.ok && again.findings.length === 0);
  const syn = JSON.parse(checkJson("grammar:\n  B -> b ;\n"));
  check("grammarlab: синтаксическая ошибка S007", !syn.ok && syn.parse[0].code === "S007");
} else {
  check("grammarlab: бандл собран", false, "нет " + gl);
}

// ---- playground компилятора FSM
const pg = join(site, "playground");
if (!existsSync(join(pg, "index.html"))) {
  console.log("skip fsmc: страница не опубликована");
} else if (existsSync(join(pg, "fsmc-bundle.zip"))) {
  load(join(pg, "fsmc-bundle.zip"), "/home/pyodide/fsmc");
  const compile = pyodide.runPython("from fsmc.web import compile_json; compile_json");
  const examples = JSON.parse(readFileSync(join(pg, "examples.json"), "utf-8"));
  const atm = examples.find((e) => e.id === "atm");
  for (const fe of ["antlr", "lark"]) {
    const r = JSON.parse(compile(atm.source, fe));
    check(`fsmc: atm.fsm (${fe})`, r.ok && r.wasm, (r.diagnostics || []).map((d) => d.code).join(","));
  }
  const neg = examples.find((e) => e.group === "Негативные тесты");
  const r = JSON.parse(compile(neg.source, "lark"));
  check(`fsmc: ${neg.id} отвергнут`, !r.ok);
} else {
  check("fsmc: бандл собран", false, "нет " + pg);
}

process.exit(failed ? 1 : 0);
