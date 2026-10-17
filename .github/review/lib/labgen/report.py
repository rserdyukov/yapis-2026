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
              "cascade": "каскад сообщений", "elsewhere": "ошибка не в том месте", "not-run": "не запускался"}

# Сводка для check.out: что из найденного — факт запуска, а что — кандидат.
# Падение и таймаут не зависят от правил языка; «ошибка не найдена» и
# «ложная ошибка» могут оказаться нормой варианта (неявное приведение,
# вызов до объявления), поэтому для модели это повод проверить README.
SUMMARY_FACT = {"crash", "timeout"}
SUMMARY_MAX_ITEMS = 8


def _clip(s: str, n: int = 160) -> str:
    s = " ".join(s.split())
    return s if len(s) <= n else s[:n - 1] + "…"


def write_summary(path: Path, work: Path, muts: list[Mutant], meta: dict) -> None:
    ran = [m for m in muts if m.verdict not in {"", "not-run"}]
    bad = [m for m in ran if m.verdict in BAD]
    L = [f"Лексер: {meta['lexer']}; исходные примеры: {', '.join(meta['seeds']) or 'нет'}"
         + (f"; не прошли и пропущены: {', '.join(meta['seeds_failed'])}" if meta['seeds_failed'] else ""),
         "Мутант — корректный пример студента с одним изменением, для которого известно, что должен ответить "
         "анализатор. Строка «ЗАМЕЧАНИЕ» — факт запуска (трасса, таймаут). Строка «ПРОВЕРИТЬ» — кандидат: "
         "сверь с README и вариантом, прежде чем писать замечание; мутация могла задеть то, что вариант разрешает.",
         ""]
    ops: dict[str, dict[str, int]] = {}
    for m in muts:
        ops.setdefault(m.op, {}).setdefault(m.verdict or "not-run", 0)
        ops[m.op][m.verdict or "not-run"] += 1
    for op, c in ops.items():
        exp = next(m.expect for m in muts if m.op == op)
        parts = ", ".join(f"{VERDICT_RU.get(k, k)} {v}" for k, v in sorted(c.items()))
        L.append(f"  {op} (ожидание: {EXPECT_RU[exp]}): {parts}")
    L.append("")
    for m in bad[:SUMMARY_MAX_ITEMS]:
        tag = "ЗАМЕЧАНИЕ" if m.verdict in SUMMARY_FACT else "ПРОВЕРИТЬ"
        out = [ln for ln in m.output.strip().splitlines() if ln.strip()]
        L += [f"--- {m.id} {m.op}: {m.seed}, строка {m.line} — {m.desc}",
              f"    было:  {_clip(m.before)}",
              f"    стало: {_clip(m.after)}",
              f"    вывод (код {m.exit}): {_clip(out[-1] if m.verdict == 'crash' and out else (out[0] if out else 'пусто'))}",
              f"    {tag}: {VERDICT_RU.get(m.verdict, m.verdict)}, ожидалось {EXPECT_RU[m.expect]}"
              + (f" ({m.note})" if m.note else "")]
    if len(bad) > SUMMARY_MAX_ITEMS:
        L.append(f"... и ещё {len(bad) - SUMMARY_MAX_ITEMS} расхождений того же вида.")
    not_run = sum(m.verdict in {"", "not-run"} for m in muts)
    L.append(f"Счётчики мутантов (копируй как есть): построено {len(muts)}, запущено {len(ran)}, "
             f"расхождений {len(bad)}, не запускалось {not_run}")
    path.write_text("\n".join(L) + "\n", encoding="utf-8")


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
