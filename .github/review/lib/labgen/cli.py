"""Командная строка labgen."""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import random
import re
import shutil
import sys
from pathlib import Path

from . import __doc__ as PKG_DOC
from .judge import judge, run_one
from .lexing import Lexed, find_grammar, find_jar, infer_lang, lex_antlr, lex_fallback, read_props
from .mutate import Mutant, gen_sem, gen_syn
from .report import BAD, VERDICT_RU, write_report


def main() -> int:
    ap = argparse.ArgumentParser(prog="labgen", description=PKG_DOC.splitlines()[0])
    ap.add_argument("work", type=Path)
    ap.add_argument("--mode", choices=["sem", "syn", "all"], default="sem")
    ap.add_argument("--out", type=Path)
    ap.add_argument("--max-per-op", type=int, default=4)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--timeout", type=int, default=30)
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--antlr-jar")
    ap.add_argument("--no-antlr", action="store_true", help="только запасной лексер")
    ap.add_argument("--no-run", action="store_true", help="только сгенерировать мутанты")
    a = ap.parse_args()

    work = a.work.resolve()
    if not (work / "compile.sh").is_file():
        print(f"нет {work}/compile.sh", file=sys.stderr)
        return 2
    out_dir = (a.out or work / ".labgen").resolve()
    shutil.rmtree(out_dir, ignore_errors=True)
    (out_dir / "mutants").mkdir(parents=True)

    grammars = find_grammar(work)
    if not grammars:
        print("не найдена грамматика .g4", file=sys.stderr)
        return 2
    gtext = "\n".join(g.read_text(errors="replace") for g in grammars)
    jar = None if a.no_antlr else find_jar(a.antlr_jar)
    ex_dir = next((work / d for d in ("examples", "example", "tests", "samples") if (work / d).is_dir()), None)
    if ex_dir is None:
        print("нет каталога examples/ с примерами", file=sys.stderr)
        return 2
    if ex_dir.name != "examples":
        print(f"ПРЕДУПРЕЖДЕНИЕ: примеры в {ex_dir.name}/, по GUIDE.md должны быть в examples/", file=sys.stderr)
    seeds = sorted(p for p in ex_dir.glob("*") if p.is_file() and not p.name.startswith("error")
                   and not p.name.startswith("."))
    lexer_used = "ANTLR" if jar else "запасной"
    lexed = []
    for p in seeds:
        text = p.read_text(encoding="utf-8", errors="replace")
        toks = lex_antlr(jar, grammars, p) if jar else None
        if toks is None:
            lexer_used = "запасной" if not jar else "ANTLR + запасной"
            toks = lex_fallback(text, set(re.findall(r"'((?:[^'\\]|\\.)+)'", gtext)))
        lexed.append(Lexed(p, text, toks))
    li = infer_lang(lexed, gtext)
    li.props = read_props(work / "README.md")

    # Исходные примеры должны проходить, иначе мутанты от них бессмысленны.
    ok_seeds, failed = [], []
    for lx in lexed:
        rc, _ = run_one(work, lx.path, a.timeout)
        (ok_seeds if rc == 0 else failed).append(lx)

    rng = random.Random(a.seed)
    muts: list[Mutant] = []
    for lx in ok_seeds:
        if a.mode in {"sem", "all"}:
            muts += gen_sem(lx, li)
        if a.mode in {"syn", "all"}:
            muts += gen_syn(lx, li)
    # Не больше N на операцию: разные файлы и строки, детерминированно.
    picked: list[Mutant] = []
    by_op: dict[str, list[Mutant]] = {}
    for m in muts:
        by_op.setdefault(m.op, []).append(m)
    for op, ms in by_op.items():
        seen, uniq = set(), []
        for m in ms:
            if m.text not in seen:
                seen.add(m.text)
                uniq.append(m)
        rng.shuffle(uniq)
        # По кругу между исходными файлами, чтобы не брать все мутанты из одного.
        rank, cnt = {}, {}
        for k, m in enumerate(uniq):
            cnt[m.seed] = cnt.get(m.seed, 0) + 1
            rank[k] = cnt[m.seed]
        order = sorted(range(len(uniq)), key=lambda k: rank[k])
        picked += [uniq[k] for k in order[:a.max_per_op]]
    for k, m in enumerate(picked, 1):
        m.id = f"{m.mode}{k:03d}"
        (out_dir / "mutants" / f"{m.id}.txt").write_text(m.text, encoding="utf-8")

    meta = {"props": li.props, "lexer": lexer_used, "grammar": [str(g.relative_to(work)) for g in grammars],
            "seeds": [lx.path.name for lx in ok_seeds], "seeds_failed": [lx.path.name for lx in failed],
            "id_type": li.id_type, "num_types": sorted(li.num_types), "str_types": sorted(li.str_types)}
    if a.no_run:
        write_report(out_dir, work, picked, meta)
        print(f"мутантов: {len(picked)} → {out_dir}/mutants")
        return 0

    def go(m: Mutant):
        m.exit, m.output = run_one(work, out_dir / "mutants" / f"{m.id}.txt", a.timeout)
        judge(m)
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        list(ex.map(go, picked))

    write_report(out_dir, work, picked, meta)
    bad = [m for m in picked if m.verdict in BAD]
    inv = sum(m.verdict == "invalid" for m in picked)
    els = sum(m.verdict == "elsewhere" for m in picked)
    print(f"мутантов: {len(picked)}, расхождений: {len(bad)}, не в том месте: {els}, отброшено: {inv} "
          f"→ {out_dir}/report.md")
    for m in bad:
        print(f"  {m.id}: {VERDICT_RU[m.verdict]} — {m.seed}:{m.line} {m.desc}")
    return 1 if bad else 0
