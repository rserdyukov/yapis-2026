#!/usr/bin/env python3
"""Массовое заведение репозиториев студентов по списку из CSV.

ИДЕМПОТЕНТНОСТЬ — главное свойство этой команды. Список студентов
заполняется постепенно (логины GitHub появляются не сразу), поэтому
enroll рассчитан на многократный запуск: каждый следующий прогон
доделывает только то, чего не хватает, и НИКОГДА не трогает уже
существующие репозитории.

Для каждого студента проверяется отдельно:
  1. репозиторий существует?      нет -> создать из шаблона
  2. студент уже коллаборатор?    нет -> пригласить
  3. приглашение уже отправлено?  да  -> ничего не делать

Ничего не удаляется и не перезаписывается: работа студента и его настройки
в безопасности при любом числе повторных запусков.

Формат CSV (первая строка — заголовки):

    ФИО,Группа,Github
    Астахов Артём Сергеевич,321701,L1x0
    Войшнис Глеб Викторович,321701,

Пустая колонка Github — нормально: репозиторий создастся, а приглашение
уйдёт при следующем запуске, когда логин появится в таблице.

Имя репозитория: <PREFIX><группа>-<фамилия транслитом>, например
yapis-2026-321701-astakhov. Фамилия берётся из первого слова ФИО.

Использование:
    enroll.py --org ORG --prefix yapis-2026- --template owner/repo \\
              --csv students.csv [--group 321701] [--apply] [--json]

Без --apply выполняется сухой прогон: показывает план и не меняет ничего.
"""

import argparse
import csv
import json
import re
import subprocess
import sys

# Транслитерация фамилий в имена репозиториев. Таблица по ГОСТ-подобному
# упрощённому правилу: результат должен быть узнаваем преподавателем и
# валиден как имя репозитория GitHub.
TRANSLIT = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e",
    "ж": "zh", "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m",
    "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
    "ф": "f", "х": "kh", "ц": "ts", "ч": "ch", "ш": "sh", "щ": "shch",
    "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu", "я": "ya",
    # Белорусские буквы: список студентов может быть на любом из двух языков.
    "і": "i", "ў": "u", "'": "",
}


def translit(name):
    """Фамилия -> безопасное имя для репозитория."""
    out = "".join(TRANSLIT.get(ch, ch) for ch in name.strip().lower())
    # Всё, что не влезло в таблицу (дефисы в двойных фамилиях, латиница),
    # приводим к безопасному подмножеству: GitHub допускает [A-Za-z0-9._-].
    out = re.sub(r"[^a-z0-9-]+", "-", out).strip("-")
    return out


def gh(args, check=True):
    """Вызывает gh. Возвращает (код, stdout, stderr)."""
    p = subprocess.run(["gh", *args], capture_output=True, text=True)
    if check and p.returncode != 0:
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def repo_exists(org, repo):
    code, _, _ = gh(["repo", "view", f"{org}/{repo}", "--json", "name"])
    return code == 0


def collaborators(org, repo):
    """Логины с доступом (в нижнем регистре). Преподаватели тоже здесь."""
    code, out, _ = gh(["api", f"repos/{org}/{repo}/collaborators",
                       "--paginate", "--jq", ".[].login"])
    if code != 0:
        return None
    return {l.strip().lower() for l in out.splitlines() if l.strip()}


def pending_invites(org, repo):
    """Логины с неприня́тым приглашением.

    Приглашение НЕ делает студента коллаборатором, пока он его не принял,
    поэтому проверять нужно оба списка — иначе повторный запуск слал бы
    приглашение заново каждый раз.
    """
    code, out, _ = gh(["api", f"repos/{org}/{repo}/invitations",
                       "--paginate", "--jq", ".[].invitee.login"])
    if code != 0:
        return None
    return {l.strip().lower() for l in out.splitlines() if l.strip()}


def login_exists(login):
    """Есть ли такой аккаунт на GitHub.

    Опечатка в таблице иначе приводит к приглашению, которое никто не
    получит: GitHub принимает PUT на несуществующего пользователя ошибкой,
    но она теряется среди остальных строк вывода.
    """
    code, _, _ = gh(["api", f"users/{login}", "--jq", ".login"])
    return code == 0


def read_students(path, only_group=None):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.DictReader(fh))

    students, problems = [], []
    for i, row in enumerate(rows, start=2):  # +2: заголовок и нумерация с 1
        norm = { (k or "").strip().lower(): (v or "").strip()
                 for k, v in row.items() }
        fio = norm.get("фио") or norm.get("name") or ""
        group = norm.get("группа") or norm.get("group") or ""
        login = norm.get("github") or norm.get("логин") or ""

        if not fio:
            continue  # пустая строка в конце таблицы — не ошибка
        if not group:
            problems.append(f"строка {i}: у «{fio}» не указана группа")
            continue
        if only_group and group != only_group:
            continue

        surname = fio.split()[0]
        slug = translit(surname)
        if not slug:
            problems.append(f"строка {i}: не удалось получить имя из «{fio}»")
            continue

        students.append({
            "fio": fio, "group": group, "login": login,
            "slug": slug, "row": i,
        })
    return students, problems


def check_collisions(students, prefix):
    """Два студента не должны претендовать на один репозиторий."""
    seen, dups = {}, []
    for s in students:
        repo = f"{prefix}{s['group']}-{s['slug']}"
        s["repo"] = repo
        if repo in seen:
            dups.append((repo, seen[repo]["fio"], s["fio"]))
        else:
            seen[repo] = s
    return dups


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--org", required=True)
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--template", required=True)
    ap.add_argument("--csv", required=True)
    ap.add_argument("--group", default="", help="обработать только эту группу")
    ap.add_argument("--apply", action="store_true",
                    help="выполнить изменения (без него — сухой прогон)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    students, problems = read_students(args.csv, args.group or None)
    if not students:
        print("В списке нет студентов (проверьте --csv и --group).", file=sys.stderr)
        return 1

    dups = check_collisions(students, args.prefix)
    if dups:
        print("ОШИБКА: разные студенты дают одно имя репозитория:", file=sys.stderr)
        for repo, a, b in dups:
            print(f"  {repo}: «{a}» и «{b}»", file=sys.stderr)
        print("Переименуйте одного в таблице (например, добавьте инициал).",
              file=sys.stderr)
        return 1

    # Логины не должны повторяться: один человек — один репозиторий.
    by_login = {}
    for s in students:
        if not s["login"]:
            continue
        key = s["login"].lower()
        by_login.setdefault(key, []).append(s["fio"])
    for login, fios in by_login.items():
        if len(fios) > 1:
            problems.append(f"логин {login} указан у нескольких студентов: {', '.join(fios)}")

    # Проверяем логины до любых изменений: лучше остановиться на опечатке,
    # чем создать репозиторий и не суметь пригласить в него студента.
    unknown = []
    for s in students:
        if s["login"] and not login_exists(s["login"]):
            unknown.append(s)
    if unknown:
        for s in unknown:
            problems.append(
                f"строка {s['row']}: аккаунт GitHub «{s['login']}» "
                f"не существует ({s['fio']})")
        # Репозиторий всё равно создадим — работа студента от логина не
        # зависит. Но приглашать по неверному логину не будем.
        for s in unknown:
            s["login"] = ""

    plan = {"create": [], "invite": [], "ready": [], "waiting_login": []}

    for s in students:
        repo = s["repo"]
        exists = repo_exists(args.org, repo)
        s["exists"] = exists

        if not exists:
            plan["create"].append(s)
            if s["login"]:
                plan["invite"].append(s)
            else:
                plan["waiting_login"].append(s)
            continue

        # Репозиторий есть — решаем только вопрос доступа.
        if not s["login"]:
            plan["waiting_login"].append(s)
            continue

        collabs = collaborators(args.org, repo)
        invites = pending_invites(args.org, repo)
        if collabs is None or invites is None:
            problems.append(f"{repo}: не удалось прочитать доступы")
            continue

        login = s["login"].lower()
        if login in collabs:
            s["state"] = "коллаборатор"
            plan["ready"].append(s)
        elif login in invites:
            s["state"] = "приглашение отправлено"
            plan["ready"].append(s)
        else:
            plan["invite"].append(s)

    if args.json:
        print(json.dumps({
            "plan": {k: [{"repo": s["repo"], "fio": s["fio"],
                          "login": s["login"], "group": s["group"]}
                         for s in v] for k, v in plan.items()},
            "problems": problems,
        }, ensure_ascii=False, indent=2))
        return 0

    print(f"Организация: {args.org}")
    print(f"Шаблон:      {args.template}")
    print(f"Студентов в списке: {len(students)}"
          + (f" (группа {args.group})" if args.group else ""))
    print()

    if plan["create"]:
        print(f"Будут СОЗДАНЫ репозитории ({len(plan['create'])}):")
        for s in plan["create"]:
            who = s["login"] or "— логин неизвестен"
            print(f"  {s['repo']:<38} {s['fio']} ({who})")
        print()

    invite_only = [s for s in plan["invite"] if s["exists"]]
    if invite_only:
        print(f"Будут ПРИГЛАШЕНЫ в существующие репозитории ({len(invite_only)}):")
        for s in invite_only:
            print(f"  {s['repo']:<38} {s['login']}")
        print()

    if plan["waiting_login"]:
        print(f"Ждут логина в таблице ({len(plan['waiting_login'])}) — "
              f"репозиторий будет готов, приглашение уйдёт позже:")
        for s in plan["waiting_login"]:
            print(f"  {s['repo']:<38} {s['fio']}")
        print()

    if plan["ready"]:
        print(f"Уже настроены, не трогаем ({len(plan['ready'])}):")
        for s in plan["ready"]:
            print(f"  {s['repo']:<38} {s['login']} — {s['state']}")
        print()

    if problems:
        print("Проблемы в данных:")
        for p in problems:
            print(f"  - {p}")
        print()

    if not args.apply:
        print("Это сухой прогон. Ничего не изменено.")
        print("Выполнить: добавьте --apply")
        return 0

    # --- Выполнение -------------------------------------------------------
    created = invited = failed = 0

    for s in plan["create"]:
        repo = s["repo"]
        code, _, err = gh([
            "repo", "create", f"{args.org}/{repo}",
            "--private", "--template", args.template,
            "--description", f"Лабораторный практикум ЯПИС — {s['fio']} ({s['group']})",
        ])
        if code != 0:
            print(f"  {repo}: ОШИБКА создания — {err.splitlines()[0] if err else '?'}")
            failed += 1
            s["create_failed"] = True
            continue
        print(f"  {repo}: создан")
        created += 1

    for s in plan["invite"]:
        if s.get("create_failed"):
            continue  # приглашать некуда
        repo = s["repo"]
        code, _, err = gh([
            "api", f"repos/{args.org}/{repo}/collaborators/{s['login']}",
            "--method", "PUT", "--field", "permission=push", "--silent",
        ])
        if code != 0:
            print(f"  {repo}: ОШИБКА приглашения {s['login']} — "
                  f"{err.splitlines()[0] if err else '?'}")
            failed += 1
            continue
        print(f"  {repo}: приглашён {s['login']}")
        invited += 1

    print()
    print(f"Создано репозиториев: {created}, отправлено приглашений: {invited}, "
          f"ошибок: {failed}.")
    if plan["waiting_login"]:
        print(f"Ждут логина: {len(plan['waiting_login'])} — заполните таблицу "
              f"и запустите enroll ещё раз.")
    print()
    print("Защита ветки main на плане Free недоступна — включите её, если у")
    print("организации платный план: ./manage.sh protect")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
