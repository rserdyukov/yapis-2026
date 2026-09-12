#!/usr/bin/env python3
"""Сбор статистики по курсу для ./manage.sh stats.

Читает данные через gh CLI (он уже авторизован) и печатает готовый отчёт.
Вынесено из manage.sh потому, что агрегация по нескольким репозиториям с
разбором дат и процентов на bash получается хрупкой и нечитаемой.

Никаких внешних сервисов и ключей: всё берётся из GitHub API и, если задан
OPENROUTER_API_KEY, из OpenRouter.

Использование:
    collect-stats.py --org ORG --prefix PREFIX [--days N] [--json]
"""

import argparse
import json
import math
import os
import subprocess
import pathlib
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

# Бесплатный план организации: 2000 минут Actions в месяц на приватные
# репозитории (см. admin/SETUP.md, раздел «Бюджеты и лимиты»).
FREE_PLAN_MINUTES = 2000

# Порог, после которого расход минут помечается как проблема.
MINUTES_WARN_RATIO = 0.8

# Сколько неудачных запусков подряд считать поводом для внимания.
FAILURE_STREAK_WARN = 2

# Во сколько раз отказы по лимитам должны превышать число опубликованных
# ревью, чтобы это считалось перекосом (лимиты слишком строгие либо
# студент пушит слишком часто).
SKIP_RATIO_WARN = 2


def course_review_limit():
    """MAX_REVIEWS_PER_DAY_TOTAL из .github/review/config.env.

    Читаем напрямую, а не через source: это Python, и запускать bash ради
    одного числа незачем. Если файл не найден или значение не задано,
    возвращаем None — тогда подсказка про лимит просто не печатается.
    """
    config = (pathlib.Path(__file__).resolve().parent.parent.parent
              / ".github" / "review" / "config.env")
    try:
        for line in config.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("MAX_REVIEWS_PER_DAY_TOTAL="):
                value = line.split("=", 1)[1].strip().strip('"').strip("'")
                return int(value)
    except (OSError, ValueError):
        return None
    return None


def gh_json(args, default):
    """Вызывает gh и разбирает JSON. При любой ошибке возвращает default."""
    try:
        out = subprocess.run(
            ["gh", *args],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except (subprocess.SubprocessError, OSError):
        return default
    if out.returncode != 0 or not out.stdout.strip():
        return default
    try:
        return json.loads(out.stdout)
    except json.JSONDecodeError:
        return default


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except ValueError:
        return None


def list_student_repos(org, prefix):
    names = gh_json(
        ["repo", "list", org, "--limit", "500", "--json", "name"],
        [],
    )
    return sorted(
        r["name"]
        for r in names
        if r.get("name", "").startswith(prefix) and not r["name"].endswith("-template")
    )


def billable_minutes(created, updated):
    """Минуты Actions за один запуск.

    GitHub тарифицирует с округлением вверх до минуты, поэтому даже
    десятисекундный job стоит одну минуту. Эндпоинт /timing на бесплатном
    плане отдаёт billable=0, так что считаем по фактической длительности —
    это оценка сверху, что для контроля бюджета и нужно.
    """
    if not created or not updated:
        return 1
    seconds = (updated - created).total_seconds()
    if seconds <= 0:
        return 1
    return max(1, math.ceil(seconds / 60))


def collect_runs(org, repo, since):
    """Запуски всех workflow репозитория за период.

    После перехода на централизованный ревьюер в репозиториях студентов
    остаётся только guard-main, а минуты ИИ-ревью расходуются в репозитории
    ревьюера (см. --reviewer-repo).
    """
    data = gh_json(
        [
            "run", "list", "--repo", f"{org}/{repo}", "--limit", "200",
            "--json", "databaseId,name,conclusion,status,createdAt,updatedAt,headBranch,event",
        ],
        [],
    )
    runs = []
    for item in data:
        created = parse_ts(item.get("createdAt"))
        if not created or created < since:
            continue
        updated = parse_ts(item.get("updatedAt"))
        runs.append(
            {
                "id": item.get("databaseId"),
                "workflow": item.get("name") or "?",
                "conclusion": item.get("conclusion") or item.get("status") or "?",
                "created": created,
                "minutes": billable_minutes(created, updated),
                "branch": item.get("headBranch") or "?",
            }
        )
    return runs


def count_skip_comments(org, repo):
    """Комментарии бота: сколько ревью опубликовано, а сколько пропущено.

    Считаем по маркерам из .github/review/messages.env, а не по тексту:
    формулировки правятся преподавателем, и привязка к ним ломала бы
    подсчёт молча. Отказы несут ai-review-skipped, сбои — ai-review-marker-failed.
    """
    prs = gh_json(
        [
            "pr", "list", "--repo", f"{org}/{repo}", "--state", "all",
            "--limit", "50", "--json", "number,comments",
        ],
        [],
    )
    published = skipped = failed = 0
    for pr in prs:
        for c in pr.get("comments") or []:
            body = c.get("body") or ""
            if "ai-review-marker" not in body:
                continue
            if "ai-review-skipped" in body:
                skipped += 1
            elif "ai-review-marker-failed" in body:
                failed += 1
            else:
                published += 1
    return published, skipped, failed


def openrouter_quota():
    """Остаток бесплатной квоты OpenRouter. None, если ключ не задан."""
    key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if not key:
        return None
    req = urllib.request.Request(
        "https://openrouter.ai/api/v1/key",
        headers={"Authorization": f"Bearer {key}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            payload = json.load(resp).get("data", {})
    except (urllib.error.URLError, json.JSONDecodeError, OSError, TimeoutError) as exc:
        return {"error": str(exc)}
    # is_free_tier=true означает "кредиты никогда не покупались". Именно от
    # этого зависит дневной лимит бесплатных моделей: без покупки — 50
    # запросов в сутки, после пополнения хотя бы на 10 кредитов — 1000
    # (см. https://openrouter.ai/docs/api-reference/limits).
    is_free = payload.get("is_free_tier")
    return {
        "usage": payload.get("usage"),
        "limit": payload.get("limit"),
        "limit_remaining": payload.get("limit_remaining"),
        "usage_daily": payload.get("usage_daily"),
        "is_free_tier": is_free,
        "free_model_rpd": 50 if is_free else 1000,
    }


def bar(used, total, width=24):
    if not total:
        return ""
    filled = min(width, int(round(width * used / total)))
    return "[" + "#" * filled + "." * (width - filled) + "]"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--org", required=True)
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--json", action="store_true", help="машиночитаемый вывод")
    ap.add_argument("--reviewer-repo", default="",
                    help="owner/repo ревьюера: его минуты считаются отдельно")
    args = ap.parse_args()

    since = datetime.now(timezone.utc) - timedelta(days=args.days)
    repos = list_student_repos(args.org, args.prefix)

    if not repos:
        print(f"В организации {args.org} нет репозиториев студентов "
              f"с префиксом {args.prefix}.")
        return 0

    problems = []
    per_repo = {}
    totals = {"minutes": 0, "runs": 0, "success": 0, "failure": 0, "other": 0}
    by_workflow = {}
    reviewer = {"minutes": 0, "runs": 0, "failure": 0}

    # Минуты ревьюера списываются с аккаунта, где лежит его репозиторий, а
    # не с квоты организации, поэтому считаем их отдельной строкой.
    if args.reviewer_repo:
        rv_owner, _, rv_name = args.reviewer_repo.partition("/")
        if rv_name:
            rv_runs = collect_runs(rv_owner, rv_name, since)
            reviewer["minutes"] = sum(r["minutes"] for r in rv_runs)
            reviewer["runs"] = len(rv_runs)
            reviewer["failure"] = sum(1 for r in rv_runs if r["conclusion"] == "failure")
            for r in rv_runs:
                w = by_workflow.setdefault(r["workflow"], {"runs": 0, "minutes": 0, "failure": 0})
                w["runs"] += 1
                w["minutes"] += r["minutes"]
                if r["conclusion"] == "failure":
                    w["failure"] += 1
            if reviewer["runs"] == 0:
                problems.append(
                    f"{args.reviewer_repo}: ревьюер не запускался за период "
                    f"— проверьте ./manage.sh doctor"
                )
            elif reviewer["failure"] >= FAILURE_STREAK_WARN:
                problems.append(
                    f"{args.reviewer_repo}: {reviewer['failure']} неудачных запусков ревьюера"
                )

    for repo in repos:
        runs = collect_runs(args.org, repo, since)
        minutes = sum(r["minutes"] for r in runs)
        success = sum(1 for r in runs if r["conclusion"] == "success")
        failure = sum(1 for r in runs if r["conclusion"] == "failure")

        totals["minutes"] += minutes
        totals["runs"] += len(runs)
        totals["success"] += success
        totals["failure"] += failure
        totals["other"] += len(runs) - success - failure

        for r in runs:
            w = by_workflow.setdefault(r["workflow"], {"runs": 0, "minutes": 0, "failure": 0})
            w["runs"] += 1
            w["minutes"] += r["minutes"]
            if r["conclusion"] == "failure":
                w["failure"] += 1

        # Серия неудач подряд — признак, что у студента что-то системно ломается.
        streak = 0
        for r in sorted(runs, key=lambda x: x["created"], reverse=True):
            if r["conclusion"] == "failure":
                streak += 1
            else:
                break
        if streak >= FAILURE_STREAK_WARN:
            problems.append(f"{repo}: {streak} неудачных запусков подряд")

        published, skipped, failed = count_skip_comments(args.org, repo)
        if skipped and not published:
            problems.append(
                f"{repo}: ревью ни разу не опубликовано, отказов по лимитам — {skipped}"
            )
        elif skipped >= published * SKIP_RATIO_WARN and skipped >= 3:
            # Перекос в сторону отказов: студент пушит слишком часто либо
            # лимиты в config.env заданы строже, чем нужно.
            problems.append(
                f"{repo}: отказов по лимитам {skipped} против {published} ревью "
                f"— проверьте MAX_REVIEWS_PER_DAY и MAX_REVIEWS_PER_PR"
            )
        # Технические сбои ревью студент видит как «не удалось выполнить»,
        # и сам починить не может — это всегда к преподавателю.
        if failed:
            problems.append(
                f"{repo}: {failed} комментариев о технической ошибке ревью "
                f"— смотрите логи workflow review"
            )

        open_prs = gh_json(
            ["pr", "list", "--repo", f"{args.org}/{repo}", "--state", "open",
             "--limit", "20", "--json", "number,headRefName"],
            [],
        )

        guard_issues = gh_json(
            ["issue", "list", "--repo", f"{args.org}/{repo}", "--state", "open",
             "--label", "guard-main", "--limit", "10", "--json", "number"],
            [],
        )
        if guard_issues:
            problems.append(
                f"{repo}: открыт(о) {len(guard_issues)} issue guard-main "
                f"(push в main в обход PR)"
            )

        per_repo[repo] = {
            "minutes": minutes,
            "runs": len(runs),
            "success": success,
            "failure": failure,
            "reviews_failed": failed,
            "reviews_published": published,
            "reviews_skipped": skipped,
            "open_prs": [p.get("headRefName") for p in open_prs],
        }

    quota = openrouter_quota()

    if totals["minutes"] >= FREE_PLAN_MINUTES * MINUTES_WARN_RATIO:
        problems.append(
            f"израсходовано {totals['minutes']} из {FREE_PLAN_MINUTES} минут Actions "
            f"— близко к лимиту бесплатного плана"
        )

    if args.json:
        print(json.dumps(
            {
                "org": args.org, "days": args.days,
                "totals": totals, "by_workflow": by_workflow,
                "reviewer": reviewer, "reviewer_repo": args.reviewer_repo,
                "repos": per_repo, "openrouter": quota, "problems": problems,
            },
            ensure_ascii=False, indent=2, default=str,
        ))
        return 0

    # --- Человекочитаемый отчёт ---
    print(f"Организация: {args.org}")
    print(f"Период: последние {args.days} дн.  Репозиториев студентов: {len(repos)}")
    print()

    print("=== GitHub Actions ===")
    pct = totals["minutes"] * 100 // FREE_PLAN_MINUTES if FREE_PLAN_MINUTES else 0
    print(f"  Минут (оценка):  {totals['minutes']} из {FREE_PLAN_MINUTES}  "
          f"{bar(totals['minutes'], FREE_PLAN_MINUTES)} {pct}%")
    print(f"  Запусков:        {totals['runs']} "
          f"(успешно {totals['success']}, ошибок {totals['failure']}, "
          f"прочее {totals['other']})")
    if by_workflow:
        print("  По workflow:")
        for name, w in sorted(by_workflow.items(), key=lambda kv: -kv[1]["minutes"]):
            print(f"    {name:<14} запусков {w['runs']:>3}, минут {w['minutes']:>4}, "
                  f"ошибок {w['failure']}")
    if args.reviewer_repo:
        # Отдельной строкой: эти минуты берутся из личной квоты владельца
        # репозитория ревьюера, а не из 2000 минут организации.
        print(f"  Ревьюер ({args.reviewer_repo}): минут {reviewer['minutes']}, "
              f"запусков {reviewer['runs']}, ошибок {reviewer['failure']}")
        print("    (списываются с квоты владельца этого репозитория, не организации)")
    print("  Оценка сверху: GitHub тарифицирует с округлением вверх до минуты.")
    print("  Точные цифры — Organization settings -> Billing.")
    print()

    print("=== Квота модели (OpenRouter) ===")
    if quota is None:
        print("  OPENROUTER_API_KEY не задан в окружении — пропущено.")
        print("  Чтобы увидеть остаток: export OPENROUTER_API_KEY=... перед запуском.")
    elif "error" in quota:
        print(f"  Не удалось получить: {quota['error']}")
    else:
        is_free = quota.get("is_free_tier")
        rpd = quota.get("free_model_rpd", 50)
        print(f"  Тариф: {'бесплатный (кредиты не покупались)' if is_free else 'платный'}")
        print(f"  Использовано всего: {quota.get('usage')}")
        if quota.get("usage_daily") is not None:
            print(f"  За сутки:           {quota.get('usage_daily')}")
        if quota.get("limit") is not None:
            print(f"  Лимит по ключу:     {quota.get('limit')} "
                  f"(остаток {quota.get('limit_remaining')})")
        print(f"  Лимит запросов бесплатных моделей: 20/мин и {rpd}/сутки на аккаунт.")

        # Одно ревью — это 3-8 запросов к модели (агент работает итеративно).
        # Считаем консервативно по 8, чтобы оценка не оказалась завышенной.
        reviews_per_day = rpd // 8
        print(f"  Это примерно {reviews_per_day} ревью в сутки "
              f"(одно ревью — 3-8 запросов).")
        if is_free:
            print("  Пополнение аккаунта на 10 кредитов поднимает лимит до 1000/сутки:")
            print("    https://openrouter.ai/settings/credits")
        else:
            # После пополнения узким местом становится не провайдер, а наш
            # собственный лимит в config.env — о нём легко забыть.
            course_limit = course_review_limit()
            if course_limit is not None and reviews_per_day > course_limit:
                print("  ВНИМАНИЕ: провайдер позволяет больше, чем настроено в курсе.")
                print(f"  Сейчас MAX_REVIEWS_PER_DAY_TOTAL={course_limit} "
                      f"(.github/review/config.env).")
                print("  Поднимите значение и выполните ./manage.sh sync-reviewer.")
    print()

    print("=== По репозиториям ===")
    print(f"  {'репозиторий':<28} {'мин':>4} {'запуск':>7} {'ошиб':>5} "
          f"{'ревью':>6} {'отказ':>6}  открытые PR")
    for repo, d in sorted(per_repo.items(), key=lambda kv: -kv[1]["minutes"]):
        prs = ", ".join(d["open_prs"]) if d["open_prs"] else "—"
        print(f"  {repo:<28} {d['minutes']:>4} {d['runs']:>7} {d['failure']:>5} "
              f"{d['reviews_published']:>6} {d['reviews_skipped']:>6}  {prs}")
    print()

    print("=== Требует внимания ===")
    if problems:
        for p in problems:
            print(f"  - {p}")
    else:
        print("  Проблем не найдено.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
