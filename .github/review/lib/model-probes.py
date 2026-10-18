#!/usr/bin/env python3
"""Зонды модели: программы, которые ИИ-ревьюер написал на этапе 1, запускаются через compile.sh.

ЗАЧЕМ. Модель, читающая код, ошибается в обе стороны: пропускает дефект
(«по коду проверка есть») и выдаёт догадку за факт («такая программа
пройдёт»). Ручное ревью курса находит дефекты запуском: пара «программа,
которую анализатор должен отвергнуть» и «почти такая же, которую должен
принять». Здесь то же для бота: модель пишет пары, скрипт их запускает и
отдаёт модели факты.

Вход — <work>/.review/model-probes.json, ответ модели этапа 1:
    {"probes": [{"id": "a1", "pair": "a", "expect": "reject" | "accept",
                 "why": "README: … / код: файл:строка", "program": "…"}]}
Выход — отчёт в stdout (идёт в промпт этапа 2 как недоверенные данные).

Вердикты:
    ЗАМЕЧАНИЕ      трасса исключения или таймаут — факт, не зависит от ожидания;
    РАСХОЖДЕНИЕ    код выхода противоречит ожиданию; «контроль пары прошёл» —
                   парная программа повела себя как ожидалось, то есть разница
                   именно в проверяемом месте;
    НЕДЕЙСТВИТЕЛЕН лексическая или синтаксическая ошибка: зонд не по грамматике,
                   о семантике ничего не говорит;
    ожидаемо       поведение совпало с ожиданием.

Использование: model-probes.py <work_dir> [--timeout 20] [--budget 180]
Код выхода всегда 0: результат — данные для модели.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from labgen.judge import classify, error_lines, run_one  # noqa: E402

MAX_PROBES = 14
MAX_PROGRAM_BYTES = 20000
MAX_WHY = 300


def clip(s: str, n: int = 200) -> str:
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[: n - 1] + "…"


def load_probes(path: Path) -> tuple[list[dict], str]:
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return [], "файл зондов не найден"
    try:
        data = json.loads(raw)
    except ValueError:
        # Ответ модели: JSON бывает обёрнут в ```json или окружён текстом.
        a, b = raw.find("{"), raw.rfind("}")
        try:
            data = json.loads(raw[a:b + 1]) if a >= 0 and b > a else None
        except ValueError as e:
            return [], f"ответ этапа 1 — не JSON ({clip(e, 120)})"
        if data is None:
            return [], "ответ этапа 1 — не JSON"
    items = data.get("probes") if isinstance(data, dict) else data
    if not isinstance(items, list):
        return [], "в ответе этапа 1 нет списка probes"
    out, seen = [], set()
    for k, p in enumerate(items[:MAX_PROBES], 1):
        if not isinstance(p, dict) or not isinstance(p.get("program"), str) or not p["program"].strip():
            continue
        expect = str(p.get("expect", "")).lower()
        if expect not in {"reject", "accept"}:
            continue
        pid = re.sub(r"[^A-Za-z0-9_-]", "", str(p.get("id") or ""))[:12] or f"p{k}"
        while pid in seen:
            pid += "x"
        seen.add(pid)
        out.append({"id": pid, "pair": re.sub(r"[^A-Za-z0-9_-]", "", str(p.get("pair") or ""))[:12],
                    "expect": expect, "why": clip(p.get("why", ""), MAX_WHY),
                    "program": p["program"][:MAX_PROGRAM_BYTES]})
    return out, ""


def examples_ext(work: Path) -> str:
    for d in ("examples", "example", "samples"):
        exs = [p for p in (work / d).glob("*") if p.is_file() and not p.name.startswith(".")] if (work / d).is_dir() else []
        if exs:
            exts = sorted({p.suffix for p in exs})
            return max(exts, key=lambda e: sum(p.suffix == e for p in exs)) or ".txt"
    return ".txt"


def run(work: Path, probes: list[dict], timeout: int, budget: int) -> list[dict]:
    pdir = work / ".review" / "model-probes"
    pdir.mkdir(parents=True, exist_ok=True)
    ext = examples_ext(work)
    deadline = time.monotonic() + budget
    for p in probes:
        # Имя файла не содержит «error»: часть compile.sh ведёт себя по имени.
        f = pdir / f"{p['id']}{ext}"
        f.write_text(p["program"] if p["program"].endswith("\n") else p["program"] + "\n", encoding="utf-8")
        p["file"] = str(f.relative_to(work))
        if time.monotonic() > deadline:
            p["rc"], p["out"], p["kind"] = None, "", "not-run"
            continue
        p["rc"], p["out"] = run_one(work, f, timeout)
        p["kind"] = "timeout" if p["rc"] == 124 else classify(p["out"])
    return probes


def verdict(p: dict) -> str:
    rc, kind = p["rc"], p["kind"]
    if kind == "not-run":
        return "не запускался"
    if kind in {"timeout", "crash"}:
        return "ЗАМЕЧАНИЕ"
    if rc != 0 and kind in {"lex", "syn"}:
        return "НЕДЕЙСТВИТЕЛЕН"
    if p["expect"] == "reject":
        return "ожидаемо" if rc != 0 else "РАСХОЖДЕНИЕ"
    return "ожидаемо" if rc == 0 else "РАСХОЖДЕНИЕ"


def report(probes: list[dict], note: str) -> str:
    L = ["Программы написаны тобой на этапе 1 и запущены через compile.sh в том же контейнере без сети.",
         "Вердикт выставлен по коду выхода и виду сообщения, а не по смыслу: ожидание («отвергнуть»/«принять»)",
         "задал ты, его правильность по README и варианту — на тебе.", ""]
    if note:
        L += [f"Зонды не запускались: {note}.", ""]
    for p in probes:
        p["verdict"] = verdict(p)
    pairs: dict[str, list[dict]] = {}
    for p in probes:
        if p["pair"]:
            pairs.setdefault(p["pair"], []).append(p)
    for p in probes:
        exp = "отвергнуть" if p["expect"] == "reject" else "принять"
        L.append(f"--- зонд {p['id']}{' (пара ' + p['pair'] + ')' if p['pair'] else ''}: ожидание — {exp}; {p['why']}")
        L.append(f"    файл: {p.get('file', '—')}")
        if p["rc"] is None:
            L.append("    РЕЗУЛЬТАТ: не запускался (исчерпан бюджет времени)")
            continue
        lines = [ln for ln in p["out"].splitlines() if ln.strip()]
        errs = error_lines(p["out"])
        shown = (lines[-1:] if p["kind"] == "crash" else errs[:2] or lines[:2]) or ["(вывод пуст)"]
        for ln in shown:
            L.append(f"    | {clip(ln)}")
        v = p["verdict"]
        if v == "ЗАМЕЧАНИЕ":
            L.append(f"    РЕЗУЛЬТАТ: ЗАМЕЧАНИЕ — {'таймаут' if p['kind'] == 'timeout' else 'трасса исключения'} (код {p['rc']})")
        elif v == "НЕДЕЙСТВИТЕЛЕН":
            L.append(f"    РЕЗУЛЬТАТ: НЕДЕЙСТВИТЕЛЕН — {'лексическая' if p['kind'] == 'lex' else 'синтаксическая'} ошибка "
                     f"(код {p['rc']}): программа не по грамматике, о семантике ничего не говорит")
        elif v == "РАСХОЖДЕНИЕ":
            mates = [q for q in pairs.get(p["pair"], []) if q is not p]
            ctrl = ""
            if mates:
                ok = all(q.get("verdict") == "ожидаемо" for q in mates)
                ctrl = "; контроль пары прошёл" if ok else "; контроль пары НЕ прошёл — сначала разберись, почему"
            what = "программа принята (код 0)" if p["expect"] == "reject" else f"программа отвергнута (код {p['rc']})"
            L.append(f"    РЕЗУЛЬТАТ: РАСХОЖДЕНИЕ — {what}{ctrl}")
        else:
            L.append(f"    РЕЗУЛЬТАТ: ожидаемо (код {p['rc']})")
    cnt = {k: sum(p.get("verdict") == k for p in probes)
           for k in ("ожидаемо", "РАСХОЖДЕНИЕ", "ЗАМЕЧАНИЕ", "НЕДЕЙСТВИТЕЛЕН", "не запускался")}
    L += ["", "Счётчики зондов модели (копируй как есть): написано " + str(len(probes)) + ", "
          + ", ".join(f"{k} {v}" for k, v in cnt.items())]
    return "\n".join(L)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("work", type=Path)
    ap.add_argument("--timeout", type=int, default=20)
    ap.add_argument("--budget", type=int, default=180)
    a = ap.parse_args()
    work = a.work.resolve()
    probes, note = load_probes(work / ".review" / "model-probes.json")
    if not note and not (work / "compile.sh").is_file():
        note = "compile.sh не найден"
    if not note and not probes:
        note = "в ответе этапа 1 нет ни одного зонда с program и expect"
    if not note:
        run(work, probes, a.timeout, a.budget)
    print(report(probes if not note else [], note))
    return 0


if __name__ == "__main__":
    sys.exit(main())
