"""report.md и report.json."""

from __future__ import annotations

import json
import os
from dataclasses import asdict
from pathlib import Path

from .mutate import Mutant


EXPECT_RU = {"error": "ошибка", "pass": "код 0", "one-error": "одна ошибка", "no-crash": "без падения"}
BAD = {"missed", "false-positive", "crash", "timeout", "wrong-kind", "exit-code", "cascade"}
VERDICT_RU = {"ok": "ожидание выполнено", "missed": "ошибка не найдена", "false-positive": "ложная ошибка",
              "crash": "аварийное завершение", "timeout": "таймаут", "invalid": "мутант отброшен",
              "wrong-kind": "не тот вид ошибки", "exit-code": "код выхода 0 при ошибке",
              "cascade": "каскад сообщений", "elsewhere": "ошибка не в том месте"}


def write_report(out_dir: Path, work: Path, muts: list[Mutant], meta: dict) -> None:
    (out_dir / "report.json").write_text(json.dumps(
        {"meta": meta, "mutants": [{k: v for k, v in asdict(m).items() if k != "text"} for m in muts]},
        ensure_ascii=False, indent=2), encoding="utf-8")
    ops: dict[str, dict[str, int]] = {}
    for m in muts:
        ops.setdefault(m.op, {}).setdefault(m.verdict, 0)
        ops[m.op][m.verdict] += 1
    L = [f"# labgen: {work}", "",
         f"Лексер: {meta['lexer']}; грамматика: {', '.join(meta['grammar'])}; "
         f"исходные примеры: {', '.join(meta['seeds'])}" + (f"; не прошли и пропущены: {', '.join(meta['seeds_failed'])}"
                                                            if meta['seeds_failed'] else ""), "",
         "| Мутация | Ожидание | Всего | ok | ошибка не найдена | ложная ошибка | аварийно | не в том месте | отброшен | прочее |",
         "|---|---|---|---|---|---|---|---|---|---|"]
    for op, c in ops.items():
        exp = next(m.expect for m in muts if m.op == op)
        other = sum(v for k, v in c.items() if k not in {"ok", "missed", "false-positive", "crash", "invalid",
                                                        "elsewhere"})
        L.append(f"| {op} | {EXPECT_RU[exp]} | {sum(c.values())} | {c.get('ok', 0)} | "
                 f"{c.get('missed', 0)} | {c.get('false-positive', 0)} | {c.get('crash', 0)} | {c.get('elsewhere', 0)} | "
                 f"{c.get('invalid', 0)} | {other} |")
    L.append("")
    for title, sel in (("Расхождения", lambda m: m.verdict in BAD),
                       ("Ошибка не в том месте — проверить вручную", lambda m: m.verdict == "elsewhere"),
                       ("Без позиции в сообщении", lambda m: m.verdict == "ok" and m.note),
                       ("Отброшенные мутанты", lambda m: m.verdict == "invalid")):
        items = [m for m in muts if sel(m)]
        if not items:
            continue
        L += [f"## {title} ({len(items)})", ""]
        for m in items:
            first = "\n".join([ln for ln in m.output.strip().splitlines() if ln.strip()][:6])
            L += [f"### {m.id} · {m.op} · {VERDICT_RU.get(m.verdict, m.verdict)}", "",
                  f"- Исходник: `{m.seed}`, строка {m.line}: {m.desc}",
                  f"- Ожидалось: {EXPECT_RU[m.expect]}; получено: код {m.exit}, вид `{m.kind}`"
                  + (f"; {m.note}" if m.note else ""),
                  f"- Запуск: `./compile.sh {os.path.relpath(out_dir / 'mutants' / (m.id + '.txt'), work)}`", "",
                  "```diff", f"- {m.before}", f"+ {m.after}", "```", "", "```", first, "```", ""]
    (out_dir / "report.md").write_text("\n".join(L), encoding="utf-8")
