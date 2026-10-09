"""Запуск compile.sh на мутанте и вердикт."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

from .mutate import Mutant


# --- запуск -------------------------------------------------------------------

CRASH_RE = re.compile(r"Traceback \(most recent call last\)|Exception in thread|^\s+at [\w.$<>]+\([\w$]+\.java:\d+\)"
                      r"|Unhandled exception|panic:|Segmentation fault|core dumped|RecursionError|StackOverflowError"
                      r"|NullPointerException|IndexOutOfBounds|KeyError:|AttributeError:|TypeError:", re.M)


# Строка сообщения об ошибке: слово «ошибка/error» и номер строки рядом.
ERR_LINE = re.compile(r"^(?=.*(?:ошибк|error))(?=.*\d).*$", re.I | re.M)


EXPLICIT_KIND = [
    ("lex", re.compile(r"лексич|lexical|lexer error|token recognition", re.I)),
    ("syn", re.compile(r"синтакс|syntax|parse error|parser error|mismatched input|extraneous input|"
                       r"no viable alternative|missing '|expecting", re.I)),
    ("sem", re.compile(r"семант|semantic", re.I)),
]


SUMMARY_LINE = re.compile(r"(найдено|всего|обнаружено|total|found)\b.*\d|^\s*\d+\s+(errors?|ошиб)", re.I)


def error_lines(output: str) -> list[str]:
    return [ln for ln in ERR_LINE.findall(output)
            if not re.search(r"\bOK\b|успешно", ln, re.I) and not SUMMARY_LINE.search(ln)]


POS_RE = re.compile(r"(?:строк[аеи]|line)\s*:?\s*(\d+)|<file>:(\d+)(?::\d+)?|\((\d+)\s*[:,]\s*\d+\)|^(\d+):\d+", re.I | re.M)


def error_positions(output: str) -> list[int]:
    out = []
    for ln in error_lines(output):
        m = POS_RE.search(ln)
        if m:
            out.append(int(next(g for g in m.groups() if g)))
    return out


def classify(output: str) -> str:
    """Вид ошибки по строкам-сообщениям (а не по всему выводу: там бывают строки
    «Синтаксический анализ... OK»)."""
    if CRASH_RE.search(output):
        return "crash"
    lines = error_lines(output)
    for ln in lines[:1]:
        for name, rx in EXPLICIT_KIND:
            if rx.search(ln):
                return name
        return "sem"
    return "?"


def run_one(work: Path, prog: Path, timeout: int) -> tuple[int, str]:
    rel = os.path.relpath(prog, work)
    out = _run(work, rel, timeout)
    # Путь к файлу в выводе (имена мутантов содержат «error», номера) мешает разбору.
    return out[0], out[1].replace(rel, "<file>")


def _run(work: Path, rel: str, timeout: int) -> tuple[int, str]:
    try:
        r = subprocess.run(["bash", "./compile.sh", rel], cwd=work, capture_output=True, text=True,
                           timeout=timeout, errors="replace", stdin=subprocess.DEVNULL)
        return r.returncode, (r.stdout + r.stderr)
    except subprocess.TimeoutExpired as e:
        return 124, f"TIMEOUT {timeout}s\n" + ((e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or ""))


def judge(m: Mutant) -> None:
    out = m.output
    m.kind = classify(out)
    if m.exit == 124:
        m.verdict = "timeout"
    elif m.kind == "crash":
        m.verdict = "crash"
    elif m.expect == "pass":
        m.verdict = "ok" if m.exit == 0 else "false-positive"
    elif m.expect == "no-crash":
        m.verdict = "ok"
    elif m.exit == 0:
        m.verdict = "exit-code" if m.kind in {"lex", "syn", "sem"} and error_lines(out) else "missed"
        if m.verdict == "exit-code":
            m.note = "сообщение об ошибке выдано, но код выхода 0"
    elif m.mode == "sem" and m.kind in {"lex", "syn"}:
        m.verdict = "invalid"
        m.note = "анализатор сообщил о синтаксической/лексической ошибке: мутант, вероятно, синтаксически неверен"
    elif m.mode == "syn" and m.kind not in {"lex", "syn"}:
        m.verdict = "wrong-kind"
        m.note = "ошибка сообщена как семантическая"
    elif m.expect == "one-error" and len(error_lines(out)) > 1:
        m.verdict = "cascade"
        m.note = f"сообщений об ошибках: {len(error_lines(out))}, ожидалось одно"
    else:
        m.verdict = "ok"
        pos = error_positions(out)
        near = set(m.lines) | {x + d for x in m.lines for d in (-1, 1)}
        if m.mode == "sem" and pos and not (set(pos) & set(m.lines if m.op != "string-arith" else near)):
            m.verdict = "elsewhere"
            m.note = f"ошибка выдана в строке {pos[0]}, а изменена строка {m.line}: найдена не та ошибка"
        elif m.mode == "syn" and pos and m.op != "unclosed-string" and not (
                set(pos) & (near | ({m.line + 2, m.line + 3} if m.op == "drop-delim" else set()))):
            m.verdict = "elsewhere"
            m.note = f"ошибка выдана в строке {pos[0]}, а изменена строка {m.line}"
        elif not pos:
            m.note = "в сообщении нет номера строки"
