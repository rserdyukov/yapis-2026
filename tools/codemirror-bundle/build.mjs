// Сборка CodeMirror 6 в один ES-модуль для docs/practice/task3-check/.
//
//   cd tools/codemirror-bundle && npm ci && node build.mjs          # пересобрать
//   node build.mjs --check                                          # CI: бандл актуален
//
// Бандл коммитится: сайту не нужен ещё один CDN, а версии зафиксированы
// в package-lock.json. Сборка детерминирована.
import { build } from "esbuild";
import { readFileSync, writeFileSync } from "node:fs";

const OUT = new URL("../../docs/practice/task3-check/codemirror.mjs", import.meta.url);
const pkg = JSON.parse(readFileSync(new URL("package.json", import.meta.url)));
const versions = Object.entries(pkg.dependencies).filter(([n]) => n !== "esbuild")
  .map(([n, v]) => `${n}@${v}`).join(", ");

const result = await build({
  entryPoints: [new URL("entry.mjs", import.meta.url).pathname],
  bundle: true, format: "esm", minify: true, write: false, target: "es2020",
  legalComments: "none",
  banner: { js: `// CodeMirror 6 (MIT, https://codemirror.net): ${versions}.\n` +
                `// Собрано tools/codemirror-bundle/build.mjs — не редактировать вручную.` },
});
const code = result.outputFiles[0].text;
if (process.argv.includes("--check")) {
  let old = "";
  try { old = readFileSync(OUT, "utf-8"); } catch { /* нет файла */ }
  if (old !== code) {
    console.error("codemirror.mjs устарел: cd tools/codemirror-bundle && npm ci && node build.mjs");
    process.exit(1);
  }
  console.log("codemirror.mjs актуален");
} else {
  writeFileSync(OUT, code);
  console.log(`codemirror.mjs: ${(code.length / 1024).toFixed(0)} КБ`);
}
