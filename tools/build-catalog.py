#!/usr/bin/env python3
"""Сборка каталога языков программирования из YAML-данных.

Источник — docs/languages/_data/ (описание схемы в README.md рядом):

  ontology.yaml           общий словарь концепций: категория → концепция →
                          допустимые значения
  languages/<id>.yaml     карточка языка: метаданные, версии, значения
                          концепций, фрагменты грамматики, примеры
  examples/<id>/          пример-витрина с секциями-маркерами snippets
  grammar/<id>/           фрагменты ANTLR-грамматик с лицензией источника

Результат — страницы в docs/languages/:

  index.md                список языков
  concepts.md             онтология и матрица «концепция × язык»
  <id>.md                 карточка языка

Страницы коммитятся, как и другие сгенерированные документы курса; CI
запускает --check и падает, если данные и страницы разошлись.

Валидация — часть --check, а не только сравнение файлов: сгенерированная
страница подключает код примеров через `--8<--`, поэтому испорченный маркер
в showcase не меняет страницу, но сломает сайт. Что именно проверяется —
см. README.md в каталоге данных.

Запуск:
    python3 tools/build-catalog.py                # собрать
    python3 tools/build-catalog.py --check        # проверить (для CI)
    python3 tools/build-catalog.py --watch        # пересобирать при правках
                                                  # (вторым терминалом к
                                                  # mkdocs serve)
    python3 tools/build-catalog.py --data DIR --out DIR   # для тестов
"""

from __future__ import annotations

import argparse
import re
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import yaml

from publication import frontmatter, page_frontmatter, publication_flag

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATA = ROOT / "docs" / "languages" / "_data"
DEFAULT_OUT = ROOT / "docs" / "languages"

GENERATED_NOTICE = (
    "<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py\n"
    "     Текст и publish карточек меняйте в docs/languages/_data/.\n"
    "     Метаданные index.md и concepts.md сохраняются при пересборке. -->"
)

SCHEMA_VERSION = 1
ALLOWED_LICENSES = {"MIT", "Apache-2.0", "BSD-3-Clause"}
ASSESSMENT_KEYS = ("readability", "writability", "reliability", "cost")
ASSESSMENT_RU = {
    "readability": "Читабельность",
    "writability": "Лёгкость создания",
    "reliability": "Надёжность",
    "cost": "Стоимость",
}
STATUS_RU = {
    "stable": "стабильно",
    "preview": "preview",
    "experimental": "экспериментально",
    "deprecated": "устарело",
}
# Тот же regex, что у pymdownx.snippets: маркер, который он не распознаёт,
# уйдёт на страницу как строка кода — поэтому проверяем здесь той же формой.
RE_SECTION = re.compile(
    r"(?i)^(?P<pre>.*?)(?P<escape>;*)-{1,}8<-{1,}[ \t]+"
    r"\[[ \t]*(?P<type>start|end)[ \t]*:[ \t]*(?P<name>[a-z][-_0-9a-z]*)[ \t]*\](?P<post>.*?)$"
)
RE_ANY_MARKER = re.compile(r"-{1,}8<-{1,}[ \t]+\[")
RE_SLUG = re.compile(r"^[a-z][-_0-9a-z]*$")
# Нетерминалы ANTLR: правила парсера начинаются со строчной буквы.
RE_NONTERMINAL = re.compile(r"\b([a-z][A-Za-z0-9_]*)\b")
ANTLR_KEYWORDS = {"returns", "locals", "throws", "catch", "finally", "options",
                  "channel", "skip", "more", "type", "mode", "pushMode",
                  "popMode", "fragment", "grammar", "parser", "lexer", "import",
                  "tokens", "this"}


class CatalogError(Exception):
    """Ошибка данных: печатается без traceback, код возврата 1."""


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    coverage: dict[str, tuple[int, int]] = field(default_factory=dict)
    uncovered: dict[str, list[str]] = field(default_factory=dict)

    def error(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)


# ------------------------------------------------------------------ загрузка

def load_yaml(path: Path):
    try:
        with path.open(encoding="utf-8") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        raise CatalogError(f"файл не найден: {path}")
    except yaml.YAMLError as e:
        raise CatalogError(f"{path}: некорректный YAML: {e}")


@dataclass
class Ontology:
    raw: dict
    concepts: dict[str, dict]          # id → концепция (с полем category)
    values: dict[str, dict[str, dict]]  # concept id → value id → значение
    categories: list[dict]

    @classmethod
    def load(cls, data_dir: Path, report: Report) -> "Ontology":
        raw = load_yaml(data_dir / "ontology.yaml")
        if raw.get("schema_version") != SCHEMA_VERSION:
            raise CatalogError(
                f"ontology.yaml: schema_version {raw.get('schema_version')!r}, "
                f"генератор поддерживает {SCHEMA_VERSION}"
            )
        concepts: dict[str, dict] = {}
        values: dict[str, dict[str, dict]] = {}
        slugs: dict[str, str] = {}
        for cat in raw.get("categories", []):
            for c in cat.get("concepts", []):
                cid = c["id"]
                if cid in concepts:
                    report.error(f"ontology: концепция {cid} объявлена дважды")
                c["category"] = cat["id"]
                concepts[cid] = c
                slug = c.get("slug")
                if not slug or not RE_SLUG.match(slug):
                    report.error(f"ontology: у {cid} нет корректного slug ([a-z][-_0-9a-z]*)")
                elif slug in slugs:
                    report.error(f"ontology: slug {slug} у {cid} и {slugs[slug]}")
                else:
                    slugs[slug] = cid
                kind = c.get("kind")
                if kind not in ("choice", "bool"):
                    report.error(f"ontology: у {cid} kind={kind!r}, допустимо choice | bool")
                if kind == "choice":
                    vals = c.get("values") or []
                    if not vals:
                        report.error(f"ontology: у {cid} kind=choice без values")
                    values[cid] = {v["id"]: v for v in vals}
                else:
                    values[cid] = {"true": {"id": "true", "ru": "да"}, "false": {"id": "false", "ru": "нет"}}
        return cls(raw, concepts, values, raw.get("categories", []))

    def by_slug(self) -> dict[str, str]:
        return {c["slug"]: cid for cid, c in self.concepts.items() if c.get("slug")}


@dataclass
class Language:
    id: str
    raw: dict
    path: Path

    @property
    def name(self) -> str:
        return self.raw["meta"]["name"]

    @property
    def versions(self) -> dict[str, dict]:
        return {str(v["id"]): v for v in self.raw.get("versions", [])}


def load_languages(data_dir: Path, report: Report) -> list[Language]:
    langs = []
    for path in sorted((data_dir / "languages").glob("*.yaml")):
        raw = load_yaml(path)
        try:
            publication_flag(raw, path)
        except ValueError as error:
            report.error(str(error))
        lid = raw.get("id")
        if lid != path.stem:
            report.error(f"{path.name}: id={lid!r} не совпадает с именем файла")
            lid = path.stem
        langs.append(Language(lid, raw, path))
    return langs


# ----------------------------------------------------------------- валидация

def parse_sections(text: str, where: str, report: Report) -> set[str]:
    """Имена секций snippets в файле; невалидный маркер — ошибка."""
    names: set[str] = set()
    open_stack: list[str] = []
    for n, line in enumerate(text.split("\n"), start=1):
        if not RE_ANY_MARKER.search(line):
            continue
        m = RE_SECTION.match(line)
        if not m:
            report.error(
                f"{where}:{n}: маркер не распознаётся snippets (имя должно быть "
                f"[a-z][-_0-9a-z]*): {line.strip()}"
            )
            continue
        name = m.group("name")
        if m.group("type").lower() == "start":
            open_stack.append(name)
            names.add(name)
        else:
            if name not in open_stack:
                report.error(f"{where}:{n}: end секции {name} без start")
            else:
                open_stack.remove(name)
    for name in open_stack:
        report.error(f"{where}: секция {name} не закрыта")
    return names


def validate_language(lang: Language, onto: Ontology, data_dir: Path, report: Report) -> None:
    p = lang.path.name
    meta = lang.raw.get("meta") or {}
    for key in ("name", "ru", "summary"):
        if not meta.get(key):
            report.error(f"{p}: meta.{key} обязателен")

    # --- versions
    versions = lang.versions
    used_versions: set[str] = set()
    roles: dict[str, str] = {}
    for v in lang.raw.get("versions", []):
        vid = str(v.get("id"))
        for key in ("label", "date"):
            if not v.get(key):
                report.error(f"{p}: versions[{vid}].{key} обязателен")
        if v.get("kind") not in ("release", "edition"):
            report.error(f"{p}: versions[{vid}].kind={v.get('kind')!r}, допустимо release | edition")
        if v.get("kind") == "edition" and str(v.get("release", "")) not in versions:
            report.error(f"{p}: versions[{vid}]: edition должна ссылаться на release из versions")
        if v.get("role"):
            if v["role"] not in ("first", "latest"):
                report.error(f"{p}: versions[{vid}].role={v['role']!r}")
            elif v["role"] in roles:
                report.error(f"{p}: role {v['role']} у версий {roles[v['role']]} и {vid}")
            roles[v["role"]] = vid
    for role in ("first", "latest"):
        if versions and role not in roles:
            report.warn(f"{p}: нет версии с role: {role}")

    # --- concepts
    showcase_needed: set[str] = set()   # slug'и, для которых секция обязательна
    concepts = lang.raw.get("concepts") or {}
    for cid, entries in concepts.items():
        c = onto.concepts.get(cid)
        if c is None:
            report.error(f"{p}: концепция {cid} не объявлена в ontology.yaml")
            continue
        if not isinstance(entries, list) or not entries:
            report.error(f"{p}: {cid} должен быть непустым списком записей")
            continue
        allowed = onto.values[cid]
        non_na = 0
        for e in entries:
            if not isinstance(e, dict) or "value" not in e:
                report.error(f"{p}: {cid}: запись без value: {e!r}")
                continue
            val = e["value"]
            sval = str(val).lower() if isinstance(val, bool) else str(val)
            if sval == "n/a":
                if not e.get("note"):
                    report.error(f"{p}: {cid}: n/a допустим только с note")
                continue
            non_na += 1
            if sval not in allowed:
                report.error(
                    f"{p}: {cid}: значение {sval!r} не входит в перечисление; "
                    f"допустимо: {', '.join(allowed)}"
                )
            for key in ("since", "until"):
                if key in e and str(e[key]) not in versions:
                    report.error(f"{p}: {cid}: {key}={e[key]!r} не найден в versions")
                if key in e:
                    used_versions.add(str(e[key]))
            if "status" in e and e["status"] not in STATUS_RU:
                report.error(f"{p}: {cid}: status={e['status']!r}, допустимо {', '.join(STATUS_RU)}")
            if "example" in e:
                ex = e["example"]
                if not isinstance(ex, dict) or "file" not in ex or "section" not in ex:
                    report.error(f"{p}: {cid}: example должен быть {{file, section}}")
        max_values = c.get("max_values")
        if max_values and non_na > max_values:
            report.error(f"{p}: {cid}: допускает {max_values} значение, задано {non_na}")
        if c.get("showcase") == "required" and non_na > 0:
            showcase_needed.add(c["slug"])

    for vid in versions:
        if vid not in used_versions and vid not in roles.values():
            report.warn(f"{p}: версия {vid} не используется в since/until и без role")

    # --- examples / showcase
    examples = lang.raw.get("examples") or []
    showcase = [e for e in examples if e.get("role") == "showcase"]
    if len(showcase) != 1:
        report.error(f"{p}: нужен ровно один пример с role: showcase")
    else:
        sc_path = data_dir / "examples" / lang.id / showcase[0].get("file", "")
        if not sc_path.is_file():
            report.error(f"{p}: файл showcase не найден: {sc_path.relative_to(data_dir)}")
        else:
            sections = parse_sections(sc_path.read_text(encoding="utf-8"), str(sc_path.relative_to(data_dir)), report)
            known = onto.by_slug()
            for s in sections:
                if s not in known:
                    report.error(f"{sc_path.relative_to(data_dir)}: секция {s} не является slug ни одной концепции")
            for slug in sorted(showcase_needed - sections):
                report.error(f"{p}: showcase без секции {slug} (концепция с showcase: required)")
    for e in examples:
        if e.get("role") != "showcase":
            ex_path = data_dir / "examples" / lang.id / e.get("file", "")
            if not ex_path.is_file():
                report.error(f"{p}: файл примера не найден: {e.get('file')}")

    # --- grammar
    grammar = lang.raw.get("grammar") or {}
    sources = {s["id"]: s for s in grammar.get("sources", [])}
    for sid, s in sources.items():
        for key in ("repo", "path", "commit"):
            if not s.get(key):
                report.error(f"{p}: grammar.sources[{sid}].{key} обязателен")
        if s.get("license") not in ALLOWED_LICENSES:
            report.error(
                f"{p}: grammar.sources[{sid}].license={s.get('license')!r}; "
                f"допустимо: {', '.join(sorted(ALLOWED_LICENSES))}"
            )
    frag_files: dict[str, set[str]] = {}
    for fr in grammar.get("fragments", []):
        if fr.get("source") not in sources:
            report.error(f"{p}: fragment {fr.get('rule')}: source={fr.get('source')!r} не объявлен")
        fname = fr.get("file")
        if not fname:
            report.error(f"{p}: fragment {fr.get('rule')}: нет file")
            continue
        fpath = data_dir / "grammar" / lang.id / fname
        if fname not in frag_files:
            if not fpath.is_file():
                report.error(f"{p}: файл грамматики не найден: grammar/{lang.id}/{fname}")
                frag_files[fname] = set()
                continue
            frag_files[fname] = parse_sections(fpath.read_text(encoding="utf-8"), f"grammar/{lang.id}/{fname}", report)
            if "notice" not in frag_files[fname]:
                report.error(f"grammar/{lang.id}/{fname}: нет секции notice с лицензией источника")
        if fr.get("rule") not in frag_files[fname]:
            report.error(f"grammar/{lang.id}/{fname}: нет секции {fr.get('rule')}")

    # --- assessment
    a = lang.raw.get("assessment")
    if a is None:
        report.warn(f"{p}: assessment не заполнен")
    else:
        for key in ASSESSMENT_KEYS:
            item = a.get(key)
            if not isinstance(item, dict) or not str(item.get("text", "")).strip():
                report.error(f"{p}: assessment.{key}.text обязателен")
                continue
            for cid in item.get("concepts", []) or []:
                if cid not in onto.concepts:
                    report.error(f"{p}: assessment.{key}: концепция {cid} не объявлена")


def validate_coverage(onto: Ontology, langs: list[Language], report: Report) -> None:
    thresholds = onto.raw.get("coverage_threshold") or {}
    for cat in onto.categories:
        total = covered = 0
        missing: list[str] = []
        for c in cat.get("concepts", []):
            if c.get("kind") != "choice":
                continue
            for vid, v in onto.values[c["id"]].items():
                total += 1
                used = any(
                    str(e.get("value")) == vid
                    for lang in langs
                    for e in (lang.raw.get("concepts") or {}).get(c["id"], [])
                    if isinstance(e, dict)
                )
                if used:
                    covered += 1
                else:
                    pending = (v.get("coverage") or {}).get("pending")
                    note = (v.get("coverage") or {}).get("note")
                    missing.append(f"{c['id']}.{vid}" + (f" (ожидается: {note})" if note else ""))
                    if not (pending and note):
                        report.error(
                            f"ontology: значение {c['id']}.{vid} не покрыто ни одним языком "
                            f"и без coverage: {{pending: true, note: ...}}"
                        )
        if total:
            report.coverage[cat["id"]] = (covered, total)
            report.uncovered[cat["id"]] = missing
            thr = thresholds.get(cat["id"])
            if thr is not None and covered / total < thr:
                report.error(
                    f"покрытие {cat['id']}: {covered}/{total} ({covered / total:.0%}) "
                    f"ниже порога {thr:.0%}"
                )


# ---------------------------------------------------------------- генерация

def md_escape(s: str) -> str:
    return str(s).replace("|", "\\|").replace("\n", " ")


def rel_example(lang: Language, e: dict) -> str:
    return f"examples/{lang.id}/{e['file']}"


def lang_page(lang: Language) -> str:
    return f"{lang.id}.md"


def fence_lang(filename: str) -> str:
    ext = Path(filename).suffix.lstrip(".")
    return {"py": "python", "rs": "rust", "kt": "kotlin", "cs": "csharp",
            "ts": "typescript", "g4": "antlr"}.get(ext, ext)


def value_label(onto: Ontology, cid: str, e: dict, lang: Language) -> str:
    val = e["value"]
    sval = str(val).lower() if isinstance(val, bool) else str(val)
    if sval == "n/a":
        return "—"
    v = onto.values[cid].get(sval, {"ru": sval})
    label = v["ru"]
    tags = []
    if "since" in e:
        tags.append(lang.versions[str(e["since"])]["label"])
    if "until" in e:
        tags.append("до " + lang.versions[str(e["until"])]["label"])
    if e.get("status") and e["status"] != "stable":
        tags.append(STATUS_RU[e["status"]])
    if tags:
        label += " (" + ", ".join(tags) + ")"
    return label


def render_sources(sources: list[dict] | None) -> str:
    if not sources:
        return ""
    parts = []
    for s in sources:
        url = s.get("url", "")
        retrieved = s.get("retrieved")
        text = s.get("title") or url
        parts.append(f"[{text}]({url})" + (f" (получено {retrieved})" if retrieved else ""))
    return "; ".join(parts)


def build_language(lang: Language, onto: Ontology, langs: list[Language]) -> str:
    r = lang.raw
    meta = r["meta"]
    out: list[str] = [GENERATED_NOTICE, "", f"# {meta['ru']}", "", meta["summary"].strip(), ""]

    # --- метаданные
    out += ["## Метаданные { #meta }", ""]
    rows = []
    if "appeared" in meta:
        ap = meta["appeared"]
        val = ap["value"] if isinstance(ap, dict) else ap
        src = render_sources(ap.get("sources")) if isinstance(ap, dict) else ""
        rows.append(("Год появления", f"{val}" + (f" — {src}" if src else "")))
    if meta.get("designers"):
        rows.append(("Авторы", ", ".join(meta["designers"])))
    if meta.get("organizations"):
        rows.append(("Организации", ", ".join(meta["organizations"])))
    if meta.get("website"):
        rows.append(("Сайт", f"<{meta['website']}>"))
    if meta.get("spec"):
        rows.append(("Спецификация", f"<{meta['spec']}>"))
    ext = []
    if meta.get("wikidata"):
        ext.append(f"[Wikidata {meta['wikidata']}](https://www.wikidata.org/wiki/{meta['wikidata']})")
    if meta.get("pldb"):
        ext.append(f"[PLDB](https://pldb.io/concepts/{meta['pldb']}.html)")
    if meta.get("hopl"):
        ext.append(f"[HOPL {meta['hopl']}](https://hopl.info/showlanguage.prx?exp={meta['hopl']})")
    if meta.get("rosetta"):
        ext.append(f"[Rosetta Code](https://rosettacode.org/wiki/Category:{meta['rosetta']})")
    if ext:
        rows.append(("Внешние каталоги", ", ".join(ext)))
    out += ["| | |", "|---|---|"]
    out += [f"| {k} | {md_escape(v)} |" for k, v in rows]
    out.append("")

    # --- версии
    if r.get("versions"):
        out += ["## Версии { #versions }", "",
                "Перечислены вехи, на которые ссылаются концепции ниже, а не все выпуски.", "",
                "| Версия | Дата | Тип | Источник |", "|---|---|---|---|"]
        kinds = {"release": "выпуск", "edition": "редакция"}
        for v in sorted(r["versions"], key=lambda v: str(v["date"])):
            kind = kinds.get(v.get("kind"), v.get("kind"))
            if v.get("kind") == "edition":
                kind += f" (с {lang.versions[str(v['release'])]['label']})"
            role = {"first": " — первый выпуск", "latest": " — актуальная"}.get(v.get("role"), "")
            out.append(f"| {v['label']}{role} | {v['date']} | {kind} | {md_escape(render_sources(v.get('sources')))} |")
        out.append("")

    # --- публикации
    if r.get("publications"):
        out += ["## Публикации { #publications }", ""]
        for pub in r["publications"]:
            authors = ", ".join(pub.get("authors", []))
            title = pub["title"]
            if pub.get("url"):
                title = f"[{title}]({pub['url']})"
            tail = ", ".join(str(x) for x in (pub.get("venue"), pub.get("year")) if x)
            out.append(f"- {authors}. *{title}*." + (f" {tail}." if tail else ""))
        out.append("")

    # --- концепции
    out += ["## Концепции { #concepts }", "",
            "Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.", ""]
    concepts = r.get("concepts") or {}
    showcase = next((e for e in r.get("examples", []) if e.get("role") == "showcase"), None)
    for cat in onto.categories:
        cat_concepts = [c for c in cat.get("concepts", []) if c["id"] in concepts]
        if not cat_concepts:
            continue
        out += [f"### {cat['ru']} {{ #{cat['id']} }}", ""]
        for c in cat_concepts:
            entries = concepts[c["id"]]
            out += [f"#### {c['ru']} {{ #{c['slug']} }}", ""]
            out.append(f"*{c.get('en', '')}* · [в онтологии](concepts.md#{c['slug']})")
            out.append("")
            for e in entries:
                line = f"- **{value_label(onto, c['id'], e, lang)}**"
                extras = []
                if e.get("applies_to"):
                    extras.append(f"для: {e['applies_to']}")
                if e.get("note"):
                    extras.append(e["note"])
                if extras:
                    line += " — " + "; ".join(extras)
                src = render_sources(e.get("sources"))
                if src:
                    line += f" ({src})"
                out.append(line)
            out.append("")
            # код: одна секция на концепцию, либо явный override
            overrides = [e["example"] for e in entries if isinstance(e.get("example"), dict)]
            snippets = overrides or (
                [{"file": showcase["file"], "section": c["slug"]}]
                if showcase and c.get("showcase") == "required"
                and any(str(e.get("value")) != "n/a" for e in entries) else []
            )
            for sn in snippets:
                path = f"examples/{lang.id}/{sn['file']}"
                out += [f"```{fence_lang(sn['file'])}", f'--8<-- "{path}:{sn["section"]}"', "```", ""]

    # --- грамматика
    g = r.get("grammar") or {}
    if g:
        out += ["## Грамматика { #grammar }", ""]
        if g.get("spec_url"):
            out += [f"Официальная грамматика: <{g['spec_url']}>.", ""]
        if g.get("fragments"):
            out += ["Фрагменты ниже взяты из сообщества grammars-v4 и **не являются нормативными**: "
                    "они иллюстрируют, как правила записываются в нотации ANTLR4, которую вы "
                    "используете в лабораторной работе 2. Нетерминалы, упомянутые в правиле, "
                    "перечислены под ним со ссылкой на полный файл.", ""]
            sources = {s["id"]: s for s in g.get("sources", [])}
            for fr in g["fragments"]:
                s = sources[fr["source"]]
                url = f"https://github.com/{s['repo']}/blob/{s['commit']}/{s['path']}"
                line_url = url + (f"#L{fr['line']}" if fr.get("line") else "")
                out += [f"### `{fr['rule']}` {{ #rule-{fr['rule'].lower()} }}", ""]
                out += ["```antlr", f'--8<-- "grammar/{lang.id}/{fr["file"]}:{fr["rule"]}"', "```", ""]
                nts = extract_nonterminals(_read_section(lang, fr, onto), fr["rule"])
                meta_line = f"Источник: [`{s['path']}`]({line_url}), {s['license']}."
                if nts:
                    meta_line += " Нетерминалы: " + ", ".join(f"[`{n}`]({url})" for n in nts) + "."
                out += [meta_line, ""]
            out += ["### Лицензия источника { #grammar-license }", ""]
            seen = set()
            for fr in g["fragments"]:
                if fr["file"] in seen:
                    continue
                seen.add(fr["file"])
                s = sources[fr["source"]]
                out += [f"`{s['repo']}` / `{s['path']}` @ `{s['commit'][:12]}` — {s['license']}:", "",
                        "```text", f'--8<-- "grammar/{lang.id}/{fr["file"]}:notice"', "```", ""]
        if g.get("links"):
            out += ["Другие грамматики и материалы:", ""]
            out += [f"- [{l['title']}]({l['url']})" for l in g["links"]]
            out.append("")

    # --- примеры
    if showcase:
        out += ["## Пример-витрина { #showcase }", "",
                "Одна программа, в которой прокомментированы конструкции, соответствующие концепциям "
                "каталога — тот же формат, что у второго примера в лабораторной работе 1. "
                "Фрагменты этого файла показаны выше у каждой концепции.", "",
                f"```{fence_lang(showcase['file'])}", f'--8<-- "examples/{lang.id}/{showcase["file"]}"', "```", ""]
    others = [e for e in r.get("examples", []) if e.get("role") != "showcase"]
    if others:
        out += ["## Другие примеры { #examples }", ""]
        for e in others:
            out += [f"### {e.get('title', e['file'])}", ""]
            if e.get("note"):
                out += [e["note"], ""]
            out += [f"```{fence_lang(e['file'])}", f'--8<-- "examples/{lang.id}/{e["file"]}"', "```", ""]

    # --- оценка
    a = r.get("assessment")
    if a:
        out += ["## Оценка по критериям лекции 20 { #assessment }", "",
                "Критерии — читабельность, лёгкость создания, надёжность, стоимость. "
                "Это оценки, а не свойства: они выводятся из концепций, на которые ссылается каждый пункт.", ""]
        for key in ASSESSMENT_KEYS:
            item = a[key]
            refs = ", ".join(f"[{onto.concepts[cid]['ru']}](#{onto.concepts[cid]['slug']})"
                             for cid in item.get("concepts", []) or [])
            out += [f"**{ASSESSMENT_RU[key]}.** {item['text'].strip()}" + (f" *({refs})*" if refs else ""), ""]

    return "\n".join(out).rstrip("\n") + "\n"


_SECTION_CACHE: dict[tuple[str, str], str] = {}


def _read_section(lang: Language, fr: dict, onto: Ontology) -> str:
    """Текст секции правила из .fragments.g4 (для извлечения нетерминалов)."""
    key = (lang.id, fr["file"])
    if key not in _SECTION_CACHE:
        _SECTION_CACHE[key] = (DATA_DIR / "grammar" / lang.id / fr["file"]).read_text(encoding="utf-8")
    text = _SECTION_CACHE[key]
    inside = False
    lines = []
    for line in text.split("\n"):
        m = RE_SECTION.match(line) if RE_ANY_MARKER.search(line) else None
        if m and m.group("name") == fr["rule"]:
            inside = m.group("type").lower() == "start"
            continue
        if inside and not m:
            lines.append(line)
    return "\n".join(lines)


def extract_nonterminals(rule_text: str, rule: str) -> list[str]:
    """Имена правил парсера, упомянутых в теле правила (без строк, действий, меток)."""
    body = re.sub(r"'(?:[^'\\]|\\.)*'", " ", rule_text)      # литералы
    body = re.sub(r"\{[^}]*\}\??", " ", body)                  # действия и предикаты
    body = re.sub(r"<[^>]*>", " ", body)                       # <assoc=right>
    body = re.sub(r"#\s*\w+", " ", body)                       # метки альтернатив
    body = re.sub(r"\b\w+\s*=", " ", body)                     # x=rule метки
    body = re.sub(r"//.*", " ", body)
    seen: list[str] = []
    for m in RE_NONTERMINAL.finditer(body):
        n = m.group(1)
        if n == rule or n in ANTLR_KEYWORDS or n in seen:
            continue
        seen.append(n)
    return seen


def build_index(langs: list[Language], onto: Ontology) -> str:
    out = [GENERATED_NOTICE, "", "# Каталог языков программирования", "",
           "Справочник к [вариантам заданий](../labs/variants.md) и к лекции о критериях оценки языков: "
           "как свойства, которые вы выбираете для своего языка, решены в реальных языках. "
           "У каждого языка — метаданные, версии-вехи, значения концепций из "
           "[общей онтологии](concepts.md), фрагменты грамматики в нотации ANTLR4 и пример-витрина "
           "с комментариями.", "",
           "| Язык | Появился | Авторы | Типизация | Память | Ошибки |", "|---|---|---|---|---|---|"]
    for lang in langs:
        m = lang.raw["meta"]
        ap = m.get("appeared", {})
        year = ap.get("value") if isinstance(ap, dict) else ap
        def joined(cid: str) -> str:
            return "; ".join(value_label(onto, cid, e, lang) for e in (lang.raw.get("concepts") or {}).get(cid, []))
        out.append(f"| [{m['ru']}]({lang_page(lang)}) | {year or ''} | {md_escape(', '.join(m.get('designers', [])))} "
                   f"| {md_escape(joined('typing.checking'))} | {md_escape(joined('memory.management'))} "
                   f"| {md_escape(joined('errors.model'))} |")
    out += ["", "<div class=\"grid cards\" markdown>", ""]
    for lang in langs:
        m = lang.raw["meta"]
        out += [f"- **[{m['ru']}]({lang_page(lang)})**", "", f"    {m['summary'].strip()}", ""]
    out += ["- **[Онтология концепций](concepts.md)**", "",
            "    Словарь концепций и матрица «концепция × язык».", "", "</div>", ""]
    out += ["## Как читать карточку", "",
            "- **Концепции** — значения из закрытых перечислений; у значения могут быть версия, с которой "
            "оно появилось, область применимости и примечание.",
            "- **Грамматика** — фрагменты community-грамматик grammars-v4; официальная спецификация "
            "каждого языка записана в своей нотации, ссылка дана.",
            "- **Пример-витрина** — формат второго примера ЛР1: одна программа, все конструкции "
            "прокомментированы.", "",
            "Как добавить язык — `docs/languages/_data/README.md` в репозитории курса.", ""]
    return "\n".join(out)


def build_concepts(langs: list[Language], onto: Ontology, report: Report) -> str:
    out = [GENERATED_NOTICE, "", "# Онтология концепций", "",
           "Общий словарь, по которому описаны все языки каталога. Значение в ячейке матрицы — из "
           "закрытого перечисления; в скобках — версия, с которой оно появилось. Подробности "
           "(область применимости, примечания, источники, код) — на карточке языка по ссылке в ячейке. "
           "«—» — концепция неприменима к языку; пустая ячейка — данных нет.", ""]
    out += ["## Покрытие { #coverage }", "",
            "Доля значений перечислений, для которых в каталоге есть хотя бы один язык. "
            "Непокрытые значения ждут языков, указанных в скобках.", "",
            "| Категория | Покрыто | Ожидают языков |", "|---|---|---|"]
    for cat in onto.categories:
        if cat["id"] in report.coverage:
            cov, tot = report.coverage[cat["id"]]
            miss = report.uncovered.get(cat["id"], [])
            out.append(f"| {cat['ru']} | {cov}/{tot} ({cov / tot:.0%}) | {md_escape('; '.join(miss)) or '—'} |")
    out.append("")
    header = "| Концепция | " + " | ".join(f"[{l.raw['meta']['ru']}]({lang_page(l)})" for l in langs) + " |"
    sep = "|---|" + "---|" * len(langs)
    for cat in onto.categories:
        out += [f"## {cat['ru']} {{ #{cat['id']} }}", ""]
        if cat.get("note"):
            out += [cat["note"].strip(), ""]
        out += [header, sep]
        for c in cat.get("concepts", []):
            cells = []
            for l in langs:
                entries = (l.raw.get("concepts") or {}).get(c["id"])
                if not entries:
                    cells.append("")
                    continue
                labels = [value_label(onto, c["id"], e, l) for e in entries]
                extra = any(e.get("applies_to") or e.get("note") for e in entries)
                cell = "; ".join(labels) + (" *" if extra else "")
                cells.append(f"[{cell}]({lang_page(l)}#{c['slug']})")
            out.append(f"| [{c['ru']}](#{c['slug']}) | " + " | ".join(cells) + " |")
        out.append("")
        for c in cat.get("concepts", []):
            out += [f"### {c['ru']} {{ #{c['slug']} }}", ""]
            desc = f"*{c.get('en', '')}*"
            if c.get("aliases"):
                desc += " · также: " + ", ".join(c["aliases"])
            out += [desc, ""]
            if c.get("note"):
                out += [c["note"].strip(), ""]
            if c.get("kind") == "choice":
                for vid, v in onto.values[c["id"]].items():
                    line = f"- `{vid}` — **{v['ru']}** (*{v.get('en', '')}*)"
                    if v.get("note"):
                        line += f": {v['note']}"
                    cov = v.get("coverage") or {}
                    if cov.get("pending"):
                        line += f" — *в каталоге пока нет; ожидается: {cov.get('note', '')}*"
                    out.append(line)
            else:
                out.append("- да / нет")
            out.append("")
    # таблица критерий × язык
    assessed = [l for l in langs if l.raw.get("assessment")]
    if assessed:
        out += ["## Оценка по критериям лекции 20 { #assessment }", "",
                "Критерии — не свойства, а оценки; каждая ссылается на концепции, из которых выводится.", "",
                "| Критерий | " + " | ".join(f"[{l.raw['meta']['ru']}]({lang_page(l)}#assessment)" for l in assessed) + " |",
                "|---|" + "---|" * len(assessed)]
        for key in ASSESSMENT_KEYS:
            cells = [md_escape(l.raw["assessment"][key]["text"].strip()) for l in assessed]
            out.append(f"| {ASSESSMENT_RU[key]} | " + " | ".join(cells) + " |")
        out.append("")
    return "\n".join(out)


# ------------------------------------------------------------------- main

DATA_DIR = DEFAULT_DATA


def run(data_dir: Path, out_dir: Path, check: bool) -> int:
    global DATA_DIR
    DATA_DIR = data_dir
    _SECTION_CACHE.clear()
    report = Report()
    try:
        onto = Ontology.load(data_dir, report)
        langs = load_languages(data_dir, report)
        if not langs:
            report.error(f"{data_dir / 'languages'}: нет ни одного языка")
        for lang in langs:
            validate_language(lang, onto, data_dir, report)
        if not report.errors:
            validate_coverage(onto, langs, report)
    except CatalogError as e:
        report.error(str(e))

    for w in report.warnings:
        print(f"  предупреждение: {w}")
    for cat, (cov, tot) in report.coverage.items():
        print(f"  покрытие {cat}: {cov}/{tot} ({cov / tot:.0%})")
    if report.errors:
        print("Ошибки в данных каталога:", file=sys.stderr)
        for e in report.errors:
            print(f"  {e}", file=sys.stderr)
        return 1

    public_langs = [lang for lang in langs if publication_flag(lang.raw, lang.path)]
    public_report = Report()
    # Полнота всей базы проверена выше. Публичная матрица отражает только
    # опубликованное подмножество; скрытие карточки не требует менять онтологию.
    validate_coverage(onto, public_langs, public_report)
    pages: dict[Path, str] = {
        out_dir / "index.md": page_frontmatter(out_dir / "index.md") + build_index(public_langs, onto),
        out_dir / "concepts.md": page_frontmatter(out_dir / "concepts.md") + build_concepts(public_langs, onto, public_report),
    }
    for lang in langs:
        pages[out_dir / lang_page(lang)] = frontmatter({"publish": publication_flag(lang.raw, lang.path)}) + build_language(lang, onto, langs)

    stale: list[str] = []
    for path, expected in pages.items():
        rel = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
        if check:
            current = path.read_text(encoding="utf-8") if path.exists() else None
            if current != expected:
                stale.append(str(rel))
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists() and path.read_text(encoding="utf-8") == expected:
            print(f"  без изменений: {rel}")
        else:
            path.write_text(expected, encoding="utf-8")
            print(f"  обновлён:      {rel}")

    # сироты: страницы без данных
    if out_dir.is_dir():
        for md in sorted(out_dir.glob("*.md")):
            if md not in pages:
                rel = md.relative_to(ROOT) if md.is_relative_to(ROOT) else md
                if check:
                    stale.append(f"{rel} (лишний файл: нет данных в _data/languages/)")
                else:
                    md.unlink()
                    print(f"  удалён:        {rel}")

    if stale:
        print("Страницы разошлись с данными в docs/languages/_data/:", file=sys.stderr)
        for s in stale:
            print(f"  {s}", file=sys.stderr)
        print("\nЗапустите: python3 tools/build-catalog.py", file=sys.stderr)
        return 1
    return 0


def watch(data_dir: Path, out_dir: Path) -> int:
    """Пересборка при изменении данных (для работы рядом с mkdocs serve)."""
    def snapshot() -> dict[Path, float]:
        return {p: p.stat().st_mtime for p in data_dir.rglob("*") if p.is_file()}

    print(f"Слежу за {data_dir}; Ctrl+C для выхода.")
    last = snapshot()
    run(data_dir, out_dir, check=False)
    try:
        while True:
            time.sleep(1)
            cur = snapshot()
            if cur != last:
                last = cur
                print(f"--- {time.strftime('%H:%M:%S')} изменения в данных")
                run(data_dir, out_dir, check=False)
    except KeyboardInterrupt:
        return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true",
                        help="проверить данные и актуальность страниц, ничего не записывая")
    parser.add_argument("--watch", action="store_true", help="пересобирать при изменении данных")
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA, help="каталог данных (для тестов)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="каталог страниц (для тестов)")
    args = parser.parse_args()
    data_dir = args.data.resolve()
    out_dir = args.out.resolve()
    if args.watch:
        return watch(data_dir, out_dir)
    return run(data_dir, out_dir, args.check)


if __name__ == "__main__":
    sys.exit(main())
