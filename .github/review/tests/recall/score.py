#!/usr/bin/env python3
"""Разметка и оценка стенда полноты (eval-recall.sh).

    score.py list  --cases <каталог ревью> [--only <подстрока>] [--names]
    score.py score <каталог прогона> --cases <каталог ревью>

Кейс — каталог ревью скила lab-review с meta.json и досье студента
<cases>/_students/<repo>/ (findings.json, dropped.json, reviews.md).

Ожидаемое на коммите S: замечание P активно, если открыто на S или раньше
и не исправлено на S или раньше (порядок коммитов — reviews.md). P, открытые
позже, на S могли уже быть (ручное ревью их пропустило): совпадение с ними —
не ложное, но в знаменатель полноты они не входят.

Судья (OpenAI-совместимый API, JUDGE_MODEL) получает замечания бота и список
P/X и для каждого замечания бота возвращает совпадение. Ответы судьи
кэшируются в <прогон>/<кейс>/r<N>/judge.json: пересчёт бесплатен.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

SEV_RANK = {"blocker": 3, "major": 2, "minor": 1}


def load(p: Path, default):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


def entries(d: dict) -> dict[str, dict]:
    return {k: v for k, v in d.items() if not k.startswith("_") and isinstance(v, dict)}


def commit_order(dossier: Path) -> list[str]:
    seen: list[str] = []
    for sha in re.findall(r"`([0-9a-f]{7})`", (dossier / "reviews.md").read_text(encoding="utf-8")):
        if sha not in seen:
            seen.append(sha)
    return seen


def case_truth(case: Path, cases: Path) -> dict | None:
    meta = load(case / "meta.json", None)
    if not meta:
        return None
    dossier = cases / "_students" / meta["repo"].split("/")[1]
    if not (dossier / "findings.json").exists() or not (dossier / "reviews.md").exists():
        return None
    sha = meta["head"][:7]
    order = commit_order(dossier)
    if sha not in order:
        return None
    pos = {s: i for i, s in enumerate(order)}
    at = pos[sha]
    findings = []
    for pid, f in entries(load(dossier / "findings.json", {})).items():
        if f.get("opened") not in pos:
            continue
        opened = pos[f["opened"]]
        fixed = pos.get(f.get("fixed") or "", None)
        if opened > at:
            status = "later"
        elif fixed is not None and fixed <= at:
            status = "fixed"
        else:
            status = "active"
        sev = (f.get("severity_history") or {}).get(sha, f.get("severity", "minor"))
        findings.append({"id": pid, "status": status, "severity": sev, "title": f.get("title", ""),
                         "where": f.get("where", ""), "rules": f.get("rules", [])})
    dropped = [{"id": xid, "claim": x.get("claim") or x.get("what", ""), "why": x.get("why") or x.get("reason", "")}
               for xid, x in entries(load(dossier / "dropped.json", {})).items()
               if x.get("sha") in pos and pos[x["sha"]] <= at]
    return {"case": case.name, "repo": meta["repo"], "sha": sha, "task": meta.get("task"),
            "findings": findings, "dropped": dropped}


def all_cases(cases: Path, only: str = "") -> list[dict]:
    out = []
    for d in sorted(cases.iterdir()):
        if d.name.startswith("_") or not (d / "meta.json").exists() or only not in d.name:
            continue
        if not (d / "src" / ".git").exists() or not (d / "pr-diff.txt").exists():
            continue
        t = case_truth(d, cases)
        if t:
            out.append(t)
    return out


def cmd_list(a) -> int:
    cs = all_cases(a.cases, a.only or "")
    if a.names:
        print("\n".join(c["case"] for c in cs))
        return 0
    for c in cs:
        act = [f for f in c["findings"] if f["status"] == "active"]
        big = [f["id"] for f in act if SEV_RANK.get(f["severity"], 1) >= 2]
        print(f"{c['case']:52} ЛР{c['task']}  активных P {len(act):2} (major+ {len(big)}: {' '.join(big)}), X {len(c['dropped'])}")
    return 0


# --- замечания бота ------------------------------------------------------------

ITEM = re.compile(r"^(\d+)\.\s+(.*)")


def bot_items(text: str) -> list[dict]:
    """Нумерованный список раздела «Замечания» (до таблицы проверок)."""
    res, cur, on = [], None, False
    for line in text.splitlines():
        if re.match(r"^\s*(#+\s*|\*\*)Замечани", line):
            on = True
            continue
        if not on:
            continue
        if re.match(r"^\s*(#+\s*|\*\*)(Выполненные проверки|Что проверено)", line) or re.match(r"^\s*\|", line):
            break
        m = ITEM.match(line)
        if m:
            if cur:
                res.append(cur)
            cur = {"n": int(m.group(1)), "text": m.group(2).strip()}
        elif cur and line.strip():
            cur["text"] += " " + line.strip()
    if cur:
        res.append(cur)
    for it in res:
        it["text"] = it["text"][:1500]
        m = re.match(r"\*\*([^*]{0,60}?)[.:]", it["text"])
        low = it["text"][:120].lower()
        it["bot_major"] = bool(re.search(r"существенн|блокир|критич", low))
    return res


# --- судья ---------------------------------------------------------------------

JUDGE_PROMPT = """Ты сверяешь автоматическое ревью лабораторной работы (компилятор, ЛР{task}) с разметкой преподавателя.

Замечания бота (нумерованы):
{bot}

Подтверждённые дефекты (P). status: active — есть на этом коммите; later — найден преподавателем позже, но мог быть и здесь; fixed — уже исправлен до этого коммита.
{findings}

Отброшенные преподавателем подозрения (X) — заведомо ложные утверждения:
{dropped}

Для каждого замечания бота определи:
- "match": id P, о котором говорит замечание (тот же дефект: та же причина или то же наблюдаемое поведение; формулировка может отличаться), либо id X, если замечание повторяет отброшенное подозрение, либо null;
- "also": список других P, которые замечание тоже покрывает (если в одном пункте несколько дефектов), иначе [];
- "kind" для match = null: "plausible" — похоже на реальный дефект, которого нет в разметке; "doubtful" — сомнительно или противоречит описанию варианта/README по тексту; "nitpick" — косметика без влияния на поведение.
Совпадение только по общей теме («области видимости», «README») без того же конкретного дефекта — не совпадение.

Ответь ТОЛЬКО JSON без пояснений:
{{"items":[{{"n":1,"match":"P3","also":[],"kind":null}}, ...]}}
"""


def judge_key() -> tuple[str, str, str]:
    base = os.environ.get("JUDGE_BASE_URL", "https://litellm.playrix.com/v1")
    key = os.environ.get("JUDGE_API_KEY", "")
    if not key:
        auth = load(Path.home() / ".local/share/opencode/auth.json", {})
        key = auth.get("litellm", {}).get("key", "")
    return base, key, os.environ.get("JUDGE_MODEL", "claude-opus-5-5")


def call_judge(prompt: str) -> dict:
    base, key, model = judge_key()
    body = json.dumps({"model": model, "messages": [{"role": "user", "content": prompt}],
                       "max_tokens": 4000, "temperature": 0}).encode()
    req = urllib.request.Request(base.rstrip("/") + "/chat/completions", data=body, method="POST",
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json",
                                          # LiteLLM за WAF отвечает 403 на User-Agent urllib.
                                          "User-Agent": "curl/8.7.1"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                txt = json.load(r)["choices"][0]["message"]["content"]
            m = re.search(r"\{.*\}", txt, re.S)
            return json.loads(m.group(0)) if m else {"items": [], "error": txt[:300]}
        except Exception as e:  # noqa: BLE001 — сеть/формат: повтор, затем отказ
            err = str(e)
    return {"items": [], "error": err}


def judge_run(run: Path, truth: dict) -> dict:
    cache = run / "judge.json"
    review = (run / "review.md").read_text(encoding="utf-8") if (run / "review.md").exists() else ""
    items = bot_items(review)
    got = load(cache, None)
    if got and not got.get("error") and got.get("_items") == [i["text"][:200] for i in items]:
        return got
    if not items:
        got = {"items": []}
    else:
        fs = [f for f in truth["findings"] if f["status"] != "fixed"] + [f for f in truth["findings"] if f["status"] == "fixed"]
        prompt = JUDGE_PROMPT.format(
            task=truth["task"],
            bot="\n".join(f"{i['n']}. {i['text']}" for i in items),
            findings="\n".join(f"- {f['id']} [{f['status']}, {f['severity']}] {f['title']} (где: {f['where']})" for f in fs) or "—",
            dropped="\n".join(f"- {x['id']}: {x['claim']} — отброшено: {x['why']}" for x in truth["dropped"]) or "—")
        got = call_judge(prompt)
    got["_items"] = [i["text"][:200] for i in items]
    got["_bot"] = items
    cache.write_text(json.dumps(got, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return got


# --- метрики -------------------------------------------------------------------

def score_run(run: Path, truth: dict) -> dict:
    meta = load(run / "run.json", {})
    j = judge_run(run, truth)
    by_id = {f["id"]: f for f in truth["findings"]}
    active = {f["id"] for f in truth["findings"] if f["status"] == "active"}
    big = {i for i in active if SEV_RANK.get(by_id[i]["severity"], 1) >= 2}
    hit: set[str] = set()
    n_x = n_later = n_fixed = 0
    kinds = {"plausible": 0, "doubtful": 0, "nitpick": 0}
    rows = []
    for it in j.get("items", []):
        ids = [x for x in [it.get("match")] + list(it.get("also") or []) if x]
        ps = [x for x in ids if x in by_id]
        if any(x.startswith("X") for x in ids) and not ps:
            n_x += 1
            tag = "X"
        elif ps:
            st = {by_id[p]["status"] for p in ps}
            hit |= {p for p in ps if by_id[p]["status"] == "active"}
            if "active" in st:
                tag = "P"
            elif "later" in st:
                n_later += 1
                tag = "later"
            else:
                n_fixed += 1
                tag = "fixed"
        else:
            k = it.get("kind") or "doubtful"
            kinds[k] = kinds.get(k, 0) + 1
            tag = k
        rows.append({"n": it.get("n"), "tag": tag, "ids": ids})
    return {"case": truth["case"], "run": run.name, "invalid": meta.get("invalid", "нет run.json"),
            "agent_s": meta.get("agent_s"), "tokens": meta.get("tokens", {}),
            "items": len(j.get("items", [])), "judge_error": j.get("error", ""),
            "active": sorted(active), "big": sorted(big), "hit": sorted(hit),
            "missed_big": sorted(big - hit), "x": n_x, "later": n_later, "fixed": n_fixed, **kinds, "rows": rows}


def cmd_score(a) -> int:
    run_dir: Path = a.run.resolve()
    truths = {t["case"]: t for t in all_cases(a.cases)}
    res = []
    for case_dir in sorted(p for p in run_dir.iterdir() if p.is_dir()):
        t = truths.get(case_dir.name)
        if not t:
            continue
        for r in sorted(case_dir.glob("r*")):
            if (r / "run.json").exists():
                res.append(score_run(r, t))
    if not res:
        print("нет результатов", file=sys.stderr)
        return 1

    def pct(x, y):
        return f"{100 * x / y:.0f}%" if y else "—"

    lines = [f"# Стенд полноты: {run_dir.name}", ""]
    env = (run_dir / "run.env").read_text(encoding="utf-8") if (run_dir / "run.env").exists() else ""
    lines += ["```", env.strip(), "```", "",
              "| Кейс | прогон | major+ найдено | все P | замечаний бота | X (ложные) | сомнит. | вне разметки | придирки | позже/испр. | время, с | пропущены major+ |",
              "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    tot = {k: 0 for k in ("big", "bighit", "act", "hit", "items", "x", "doubtful", "plausible", "nitpick", "later", "invalid")}
    for s in res:
        bh = len(set(s["big"]) & set(s["hit"]))
        tot["big"] += len(s["big"]); tot["bighit"] += bh
        tot["act"] += len(s["active"]); tot["hit"] += len(s["hit"])
        tot["items"] += s["items"]; tot["x"] += s["x"]; tot["doubtful"] += s["doubtful"]
        tot["plausible"] += s["plausible"]; tot["nitpick"] += s["nitpick"]
        tot["later"] += s["later"] + s["fixed"]; tot["invalid"] += 1 if s["invalid"] else 0
        lines.append(f"| {s['case']} | {s['run']}{' ⚠ ' + s['invalid'][:40] if s['invalid'] else ''} | {bh}/{len(s['big'])} | "
                     f"{len(s['hit'])}/{len(s['active'])} | {s['items']} | {s['x']} | {s['doubtful']} | {s['plausible']} | "
                     f"{s['nitpick']} | {s['later'] + s['fixed']} | {s['agent_s']} | {' '.join(s['missed_big'])} |")
    lines += ["", "## Итог", "",
              f"- Полнота major+: **{tot['bighit']}/{tot['big']} ({pct(tot['bighit'], tot['big'])})**",
              f"- Полнота по всем активным P: {tot['hit']}/{tot['act']} ({pct(tot['hit'], tot['act'])})",
              f"- Замечаний бота: {tot['items']}; повтор отброшенного (X): {tot['x']} ({pct(tot['x'], tot['items'])}); "
              f"сомнительных вне разметки: {tot['doubtful']}; правдоподобных вне разметки: {tot['plausible']}; придирок: {tot['nitpick']}",
              f"- Точность (P + позже найденные + правдоподобные) / все: "
              f"{pct(tot['items'] - tot['x'] - tot['doubtful'] - tot['nitpick'], tot['items'])}",
              f"- Брак ответа (не прошёл бы validate_review_text): {tot['invalid']} из {len(res)}", ""]
    errs = [s for s in res if s["judge_error"]]
    if errs:
        lines += ["Ошибки судьи: " + ", ".join(f"{s['case']}/{s['run']}" for s in errs), ""]
    (run_dir / "score.md").write_text("\n".join(lines), encoding="utf-8")
    (run_dir / "score.json").write_text(json.dumps({"total": tot, "runs": res}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("\n".join(lines))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("list")
    p.add_argument("--cases", type=Path, required=True)
    p.add_argument("--only", default="")
    p.add_argument("--names", action="store_true")
    p = sub.add_parser("score")
    p.add_argument("run", type=Path)
    p.add_argument("--cases", type=Path, required=True)
    a = ap.parse_args()
    return cmd_list(a) if a.cmd == "list" else cmd_score(a)


if __name__ == "__main__":
    sys.exit(main())
