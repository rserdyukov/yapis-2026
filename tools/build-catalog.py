#!/usr/bin/env python3
"""Сборка каталога языков программирования из YAML-данных.

Источник — docs/languages/_data/ (описание схемы в README.md рядом):

  ontology.yaml           общий словарь концепций: категория → концепция →
                          допустимые значения
  concept-guide.yaml      определения, связи понятий, вопросы, лекции
  people.yaml             люди: языки, понятия, лекции
  sources.yaml            книги, статьи, конференции, сайты, инструменты
  lab-mapping.yaml        учебные пункты → понятия
  languages/<id>.yaml     карточка языка: метаданные, версии, значения
                          концепций, фрагменты грамматики, примеры
  examples/<id>/          пример-витрина с секциями-маркерами snippets
  grammar/<id>/           фрагменты ANTLR-грамматик с лицензией источника

Результат — страницы в docs/languages/:

  index.md                список языков
  concepts.md             матрица «понятие × язык»
  glossary.md             словарь: определение, связи, языки, примеры,
                          лекции, люди и источники каждого понятия
  questions.md            проверочные вопросы
  people.md, sources.md   люди и источники онтологии
  lab-mapping.md          соответствия учебных пунктов концепциям
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
from datetime import date
from pathlib import Path

import yaml

from publication import frontmatter, metadata as page_metadata, page_frontmatter, publication_flag, published

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATA = ROOT / "docs" / "languages" / "_data"
DEFAULT_OUT = ROOT / "docs" / "languages"
# Внешние по отношению к _data/ источники связей: номера и заголовки колод
# и ручная страница различающих примеров. Их правка меняет словарь, поэтому
# --check после неё требует пересборки каталога.
SLIDES_DIR = ROOT / "docs" / "lectures" / "slides"
EXAMPLES_PAGE = ROOT / "docs" / "concepts" / "examples" / "index.md"
GARDEN_DIR = ROOT / "docs" / "garden"

GENERATED_NOTICE = (
    "<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py\n"
    "     Текст и publish карточек меняйте в docs/languages/_data/.\n"
    "     Метаданные служебных страниц (index, concepts, glossary, people, sources…)\n"
    "     сохраняются при пересборке. -->"
)

SCHEMA_VERSION = 2
LAYERS = {"language", "standard_library", "implementation", "tooling"}
CONTEXT_KEYS = ("layer", "profile", "implementation", "scope")
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

class CatalogLoader(yaml.SafeLoader):
    """Не теряем записи из-за повторных YAML-ключей."""

    def construct_mapping(self, node, deep=False):
        self.flatten_mapping(node)
        keys = set()
        for key_node, _ in node.value:
            key = self.construct_object(key_node, deep=deep)
            try:
                if key in keys:
                    raise yaml.YAMLError(f"повторный ключ {key!r}")
                keys.add(key)
            except TypeError as error:
                raise yaml.YAMLError("ключ YAML должен быть скаляром") from error
        return super().construct_mapping(node, deep=deep)


def mapping(value, where: str) -> dict:
    if not isinstance(value, dict) or any(not isinstance(k, str) for k in value):
        raise CatalogError(f"{where}: ожидается объект со строковыми ключами")
    return value


def sequence(value, where: str) -> list:
    if not isinstance(value, list):
        raise CatalogError(f"{where}: ожидается список")
    return value


def text(value, where: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CatalogError(f"{where}: ожидается непустая строка")
    return value


def optional_texts(obj: dict, keys: tuple[str, ...], where: str) -> None:
    for key in keys:
        if key in obj:
            text(obj[key], f"{where}.{key}")


def calendar_date(value, where: str) -> date:
    if type(value) is date:
        return value
    if isinstance(value, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        try:
            return date.fromisoformat(value)
        except ValueError:
            pass
    raise CatalogError(f"{where}: ожидается дата YYYY-MM-DD")


def validate_sources(obj: dict, where: str) -> None:
    for source in sequence(obj.get("sources", []), f"{where}.sources"):
        source = mapping(source, f"{where}.sources[]")
        text(source.get("url"), f"{where}.sources[].url")
        optional_texts(source, ("title",), f"{where}.sources[]")
        if "retrieved" in source:
            calendar_date(source["retrieved"], f"{where}.sources[].retrieved")


def load_yaml(path: Path) -> dict:
    try:
        with path.open(encoding="utf-8") as f:
            return mapping(yaml.load(f, Loader=CatalogLoader), str(path))
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
        if type(raw.get("schema_version")) is not int or raw["schema_version"] != SCHEMA_VERSION:
            raise CatalogError(
                f"ontology.yaml: schema_version {raw.get('schema_version')!r}, "
                f"генератор поддерживает {SCHEMA_VERSION}"
            )
        concepts: dict[str, dict] = {}
        values: dict[str, dict[str, dict]] = {}
        # All anchors share the same namespace on concepts.md.
        slugs = {s: "служебный раздел" for s in ("coverage", "assessment", "variants", "requirements")}
        categories = sequence(raw.get("categories"), "ontology.categories")
        category_ids: set[str] = set()
        for cat in categories:
            mapping(cat, "ontology.categories[]")
            catid = text(cat.get("id"), "ontology.category.id")
            if not RE_SLUG.fullmatch(catid) or catid in slugs:
                report.error(f"ontology: повторный или некорректный id категории {catid!r}")
            slugs[catid] = catid
            category_ids.add(catid)
            text(cat.get("ru"), f"ontology.{catid}.ru")
            optional_texts(cat, ("en", "note"), f"ontology.{catid}")
        for cat in categories:
            for c in sequence(cat.get("concepts"), f"ontology.{cat['id']}.concepts"):
                mapping(c, "ontology.concepts[]")
                cid = text(c.get("id"), "ontology.concept.id")
                text(c.get("ru"), f"ontology.{cid}.ru")
                optional_texts(c, ("en", "note"), f"ontology.{cid}")
                validate_sources(c, f"ontology.{cid}")
                for alias in sequence(c.get("aliases", []), f"ontology.{cid}.aliases"):
                    text(alias, f"ontology.{cid}.aliases[]")
                if cid in concepts:
                    report.error(f"ontology: концепция {cid} объявлена дважды")
                c["category"] = cat["id"]
                concepts[cid] = c
                legacy = sequence(c.get("legacy_slugs", []), f"ontology.{cid}.legacy_slugs")
                for slug in [c.get("slug"), *legacy]:
                    text(slug, f"ontology.{cid}.slug/legacy_slugs")
                    if not RE_SLUG.fullmatch(slug):
                        report.error(f"ontology: у {cid} некорректный slug {slug!r}")
                    elif slug in slugs:
                        report.error(f"ontology: slug {slug} у {cid} и {slugs[slug]}")
                    else:
                        slugs[slug] = cid
                if "max_values" in c and (type(c["max_values"]) is not int or c["max_values"] < 1):
                    report.error(f"ontology: {cid}.max_values должен быть положительным целым")
                if "showcase" in c and c["showcase"] not in ("required", "optional"):
                    report.error(f"ontology: {cid}.showcase должен быть required | optional")
                kind = c.get("kind")
                if kind not in ("choice", "bool"):
                    report.error(f"ontology: у {cid} kind={kind!r}, допустимо choice | bool")
                if kind == "choice":
                    vals = sequence(c.get("values", []), f"ontology.{cid}.values")
                    if not vals:
                        report.error(f"ontology: у {cid} kind=choice без values")
                    values[cid] = {}
                    for v in vals:
                        mapping(v, f"ontology.{cid}.values[]")
                        vid = text(v.get("id"), f"ontology.{cid}.value.id")
                        text(v.get("ru"), f"ontology.{cid}.{vid}.ru")
                        optional_texts(v, ("en", "note"), f"ontology.{cid}.{vid}")
                        validate_sources(v, f"ontology.{cid}.{vid}")
                        if vid == "n/a" or vid in values[cid]:
                            report.error(f"ontology: повторный или зарезервированный value {cid}.{vid}")
                        cov = mapping(v.get("coverage", {}), f"ontology.{cid}.{vid}.coverage")
                        if "pending" in cov and type(cov["pending"]) is not bool:
                            report.error(f"ontology: {cid}.{vid}.coverage.pending должен быть bool")
                        optional_texts(cov, ("note",), f"ontology.{cid}.{vid}.coverage")
                        values[cid][vid] = v
                else:
                    values[cid] = {"true": {"id": "true", "ru": "да"}, "false": {"id": "false", "ru": "нет"}}
        if "coverage_policy" in raw and raw["coverage_policy"] != "informational":
            report.error("ontology.coverage_policy: допустимо informational")
        thresholds = mapping(raw.get("coverage_threshold", {}), "ontology.coverage_threshold")
        for catid, threshold in thresholds.items():
            if catid not in category_ids:
                report.error(f"ontology.coverage_threshold: неизвестная категория {catid}")
            if type(threshold) not in (int, float) or not 0 <= threshold <= 1:
                report.error(f"ontology.coverage_threshold.{catid}: ожидается число от 0 до 1")
        return cls(raw, concepts, values, categories)

    def by_slug(self) -> dict[str, str]:
        return {slug: cid for cid, c in self.concepts.items()
                for slug in [c["slug"], *c.get("legacy_slugs", [])]}


@dataclass
class Language:
    id: str
    raw: dict
    path: Path
    example_sections: dict[str, set[str]] = field(default_factory=dict)

    @property
    def name(self) -> str:
        return self.raw["meta"]["name"]

    @property
    def versions(self) -> dict[str, dict]:
        return {str(v["id"]): v for v in self.raw.get("versions", [])}

    def context(self, entry: dict) -> tuple:
        defaults = {"layer": "language", "profile": self.raw.get("default_profile")}
        return tuple(entry.get(key, defaults.get(key)) for key in CONTEXT_KEYS)


def appeared_year(raw: dict) -> int | None:
    """Год появления без валидации: порядок нужен до проверки карточек."""
    meta = raw.get("meta")
    appeared = meta.get("appeared") if isinstance(meta, dict) else None
    if isinstance(appeared, dict):
        appeared = appeared.get("value")
    return appeared if type(appeared) is int else None


def load_languages(data_dir: Path, report: Report) -> list[Language]:
    """Карточки в едином порядке сайта: по году появления, затем по id.

    Этот порядок используют список, матрица и таблицы; nav в mkdocs.yml
    обязан совпадать с ним (проверяется тестом).
    """
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
    langs.sort(key=lambda lang: (appeared_year(lang.raw) or 10**6, lang.id))
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
    meta = mapping(lang.raw.get("meta", {}), f"{p}.meta")
    for key in ("name", "ru", "summary"):
        text(meta.get(key), f"{p}.meta.{key}")
    for key in ("designers", "organizations"):
        for item in sequence(meta.get(key, []), f"{p}.meta.{key}"):
            text(item, f"{p}.meta.{key}[]")
    optional_texts(meta, ("website", "spec", "wikidata", "pldb", "rosetta"), f"{p}.meta")
    if "appeared" in meta:
        appeared = meta["appeared"]
        if isinstance(appeared, dict):
            mapping(appeared, f"{p}.meta.appeared")
            validate_sources(appeared, f"{p}.meta.appeared")
            appeared = appeared.get("value")
        if type(appeared) is not int:
            raise CatalogError(f"{p}.meta.appeared: ожидается целый год или объект с value: год")
    profiles = mapping(lang.raw.get("profiles", {}), f"{p}.profiles")
    for name, description in profiles.items():
        text(name, f"{p}.profiles: имя")
        text(description, f"{p}.profiles.{name}")
    if "default_profile" in lang.raw:
        default = text(lang.raw["default_profile"], f"{p}.default_profile")
        if default not in profiles:
            report.error(f"{p}: default_profile={default!r} не объявлен в profiles")
    for pub in sequence(lang.raw.get("publications", []), f"{p}.publications"):
        mapping(pub, f"{p}.publications[]")
        text(pub.get("title"), f"{p}.publications[].title")
        optional_texts(pub, ("venue", "url"), f"{p}.publications[]")
        for author in sequence(pub.get("authors", []), f"{p}.publications[].authors"):
            text(author, f"{p}.publications[].authors[]")

    # --- versions
    versions: dict[str, dict] = {}
    dates: dict[str, date] = {}
    for v in sequence(lang.raw.get("versions", []), f"{p}.versions"):
        mapping(v, f"{p}.versions[]")
        vid = text(v.get("id"), f"{p}.versions[].id")
        if vid in versions:
            report.error(f"{p}: повторная версия {vid}")
        versions[vid] = v
        dates[vid] = calendar_date(v.get("date"), f"{p}.versions[{vid}].date")
    used_versions: set[str] = set()
    roles: dict[str, str] = {}
    for vid, v in versions.items():
        text(v.get("label"), f"{p}.versions[{vid}].label")
        optional_texts(v, ("kind", "role", "release"), f"{p}.versions[{vid}]")
        validate_sources(v, f"{p}.versions[{vid}]")
        if v.get("kind") not in ("release", "edition"):
            report.error(f"{p}: versions[{vid}].kind={v.get('kind')!r}, допустимо release | edition")
        if v.get("kind") == "edition" and versions.get(v.get("release"), {}).get("kind") != "release":
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
    showcase_needed: set[str] = set()   # concept IDs requiring a default snippet
    example_refs: list[tuple[str, dict]] = []
    concepts = mapping(lang.raw.get("concepts", {}), f"{p}.concepts")
    for cid, entries in concepts.items():
        c = onto.concepts.get(cid)
        if c is None:
            report.error(f"{p}: концепция {cid} не объявлена в ontology.yaml")
            continue
        if not isinstance(entries, list) or not entries:
            report.error(f"{p}: {cid} должен быть непустым списком записей")
            continue
        allowed = onto.values[cid]
        intervals: dict[tuple, list[tuple[int, int, str]]] = {}
        for e in entries:
            if not isinstance(e, dict) or "value" not in e:
                report.error(f"{p}: {cid}: запись без value: {e!r}")
                continue
            val = e["value"]
            sval = str(val).lower() if isinstance(val, bool) else str(val)
            if sval == "n/a":
                if not isinstance(e.get("note"), str) or not e["note"].strip():
                    report.error(f"{p}: {cid}: n/a допустим только с note")
            elif (c["kind"] == "bool" and type(val) is not bool
                  or c["kind"] == "choice" and not isinstance(val, str)
                  or sval not in allowed):
                report.error(
                    f"{p}: {cid}: значение {sval!r} не входит в перечисление; "
                    f"допустимо: {', '.join(allowed)}"
                )
            mapping(e, f"{p}.{cid}")
            optional_texts(e, (*CONTEXT_KEYS, "applies_to", "note", "since", "until", "status"), f"{p}.{cid}")
            validate_sources(e, f"{p}.{cid}")
            if e.get("layer", "language") not in LAYERS:
                report.error(f"{p}: {cid}: layer={e['layer']!r}, допустимо {', '.join(sorted(LAYERS))}")
            if "profile" in e and e["profile"] not in profiles:
                report.error(f"{p}: {cid}: profile={e['profile']!r} не объявлен в profiles")
            for key in ("since", "until"):
                if key in e and e[key] not in versions:
                    report.error(f"{p}: {cid}: {key}={e[key]!r} не найден в versions")
                if key in e:
                    used_versions.add(str(e[key]))
            if "status" in e and e["status"] not in STATUS_RU:
                report.error(f"{p}: {cid}: status={e['status']!r}, допустимо {', '.join(STATUS_RU)}")
            if "example" in e:
                ex = e["example"]
                if not isinstance(ex, dict) or "file" not in ex or "section" not in ex:
                    report.error(f"{p}: {cid}: example должен быть {{file, section}}")
                else:
                    text(ex["file"], f"{p}.{cid}.example.file")
                    text(ex["section"], f"{p}.{cid}.example.section")
                    example_refs.append((cid, ex))
            if c.get("showcase") == "required" and sval != "n/a":
                showcase_needed.add(cid)
            if all(key not in e or e[key] in dates for key in ("since", "until")):
                start = dates[e["since"]].toordinal() if "since" in e else 0
                end = dates[e["until"]].toordinal() if "until" in e else date.max.toordinal() + 1
                if start >= end:
                    report.error(f"{p}: {cid}: since должен предшествовать until (исключительно)")
                elif sval != "n/a":
                    # applies_to is explanatory prose, never an escape from cardinality.
                    context = lang.context(e)
                    intervals.setdefault(context, []).append((start, end, sval))
        max_values = c.get("max_values", 1 if c["kind"] == "bool" else None)
        if type(max_values) is int and max_values > 0:
            for context, spans in intervals.items():
                for point in sorted({start for start, _, _ in spans}):
                    active = {value for start, end, value in spans if start <= point < end}
                    if len(active) > max_values:
                        report.error(f"{p}: {cid}: max_values={max_values}, одновременно {len(active)} "
                                     f"различных значений в контексте {dict(zip(CONTEXT_KEYS, context))}")
                        break

    for vid in versions:
        if vid not in used_versions and vid not in roles.values():
            report.warn(f"{p}: версия {vid} не используется в since/until и без role")

    # --- examples / showcase
    examples = sequence(lang.raw.get("examples", []), f"{p}.examples")
    for e in examples:
        mapping(e, f"{p}.examples[]")
        text(e.get("file"), f"{p}.examples[].file")
        optional_texts(e, ("role", "title", "note"), f"{p}.examples[]")
    showcase = [e for e in examples if e.get("role") == "showcase"]
    if len(showcase) > 1:
        report.error(f"{p}: допустим только один пример с role: showcase")
    lang.example_sections.clear()

    def example_sections(filename: str) -> set[str]:
        if filename not in lang.example_sections:
            ex_path = data_dir / "examples" / lang.id / filename
            if not ex_path.is_file():
                report.error(f"{p}: файл примера не найден: examples/{lang.id}/{filename}")
                lang.example_sections[filename] = set()
            else:
                lang.example_sections[filename] = parse_sections(
                    ex_path.read_text(encoding="utf-8"), str(ex_path), report)
        return lang.example_sections[filename]

    for e in examples:
        example_sections(e["file"])
    for cid, ex in example_refs:
        if ex["section"] not in example_sections(ex["file"]):
            report.error(f"{p}: {cid}: example {ex['file']} без секции {ex['section']}")
    sections = example_sections(showcase[0]["file"]) if showcase else set()
    if showcase:
        known = onto.by_slug()
        for s in sections:
            if s not in known:
                report.error(f"{p}: showcase: секция {s} не является slug ни одной концепции")
    for cid in sorted(showcase_needed):
        c = onto.concepts[cid]
        if not sections.intersection([c["slug"], *c.get("legacy_slugs", [])]):
            report.error(f"{p}: showcase без секции {c['slug']} (концепция с showcase: required)")

    # --- grammar
    grammar = mapping(lang.raw.get("grammar", {}), f"{p}.grammar")
    optional_texts(grammar, ("spec_url",), f"{p}.grammar")
    sources = {}
    for s in sequence(grammar.get("sources", []), f"{p}.grammar.sources"):
        mapping(s, f"{p}.grammar.sources[]")
        sid = text(s.get("id"), f"{p}.grammar.sources[].id")
        if sid in sources:
            report.error(f"{p}: повторный grammar.sources id {sid}")
        sources[sid] = s
    for sid, s in sources.items():
        for key in ("repo", "path", "commit"):
            text(s.get(key), f"{p}.grammar.sources[{sid}].{key}")
        optional_texts(s, ("license",), f"{p}.grammar.sources[{sid}]")
        if s.get("license") not in ALLOWED_LICENSES:
            report.error(
                f"{p}: grammar.sources[{sid}].license={s.get('license')!r}; "
                f"допустимо: {', '.join(sorted(ALLOWED_LICENSES))}"
            )
    frag_files: dict[str, set[str]] = {}
    for fr in sequence(grammar.get("fragments", []), f"{p}.grammar.fragments"):
        mapping(fr, f"{p}.grammar.fragments[]")
        for key in ("source", "file", "rule"):
            text(fr.get(key), f"{p}.grammar.fragments[].{key}")
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
    for link in sequence(grammar.get("links", []), f"{p}.grammar.links"):
        mapping(link, f"{p}.grammar.links[]")
        for key in ("title", "url"):
            text(link.get(key), f"{p}.grammar.links[].{key}")

    # --- assessment
    a = lang.raw.get("assessment")
    if a is None:
        report.warn(f"{p}: assessment не заполнен")
    else:
        mapping(a, f"{p}.assessment")
        for key in ASSESSMENT_KEYS:
            item = a.get(key)
            if not isinstance(item, dict) or not isinstance(item.get("text"), str) or not item["text"].strip():
                report.error(f"{p}: assessment.{key}.text обязателен")
                continue
            for cid in sequence(item.get("concepts", []), f"{p}.assessment.{key}.concepts"):
                text(cid, f"{p}.assessment.{key}.concepts[]")
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
                    if onto.raw.get("coverage_policy") != "informational" and not (pending and note):
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


def mapping_anchor(mid: str) -> str:
    return mid.replace(".", "-")


def load_lab_mapping(data_dir: Path, onto: Ontology, report: Report) -> list[dict]:
    raw = load_yaml(data_dir / "lab-mapping.yaml")
    if type(raw.get("schema_version")) is not int or raw["schema_version"] != 1:
        raise CatalogError("lab-mapping.yaml: поддерживается schema_version: 1")
    mappings = sequence(raw.get("mappings"), "lab-mapping.mappings")
    ids: set[str] = set()
    anchors: set[str] = set()
    for item in mappings:
        mapping(item, "lab-mapping.mappings[]")
        mid = text(item.get("id"), "lab-mapping.id")
        if not re.fullmatch(r"[a-z][a-z0-9_.-]*", mid):
            report.error(f"lab-mapping: некорректный id {mid!r}")
        anchor = mapping_anchor(mid)
        if mid in ids or anchor in anchors or anchor in ("variants", "requirements"):
            report.error(f"lab-mapping: повторный id/anchor {mid}")
        ids.add(mid)
        anchors.add(anchor)
        text(item.get("title"), f"lab-mapping.{mid}.title")
        text(item.get("note"), f"lab-mapping.{mid}.note")
        refs = sequence(item.get("concepts"), f"lab-mapping.{mid}.concepts")
        if not refs:
            report.error(f"lab-mapping.{mid}: concepts не должен быть пустым")
        seen: set[str] = set()
        for cid in refs:
            text(cid, f"lab-mapping.{mid}.concepts[]")
            if cid not in onto.concepts:
                report.error(f"lab-mapping.{mid}: неизвестная концепция {cid}")
            if cid in seen:
                report.error(f"lab-mapping.{mid}: повторная концепция {cid}")
            seen.add(cid)
    return mappings


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
    v = onto.values[cid].get(sval, {"ru": sval})
    label = "неприменимо (n/a)" if sval == "n/a" else v["ru"]
    tags = []
    if "since" in e:
        tags.append("с " + lang.versions[str(e["since"])]["label"] + " включительно")
    if "until" in e:
        tags.append("до " + lang.versions[str(e["until"])]["label"] + " исключительно")
    if e.get("status") and e["status"] != "stable":
        tags.append(STATUS_RU[e["status"]])
    tags.append("layer: " + e.get("layer", "language"))
    profile = e.get("profile", lang.raw.get("default_profile"))
    if profile:
        tags.append(f"profile: {profile}")
    for key in ("implementation", "scope", "applies_to"):
        if key in e:
            tags.append(f"{key}: {e[key]}")
    if tags:
        label += " (" + ", ".join(tags) + ")"
    return label


def legacy_anchors(concept: dict) -> list[str]:
    anchors = [f'<a id="{slug}"></a>' for slug in concept.get("legacy_slugs", [])]
    return anchors + [""] if anchors else []


def lab_mapping_links() -> list[str]:
    return ['<a id="variants"></a>', '<a id="requirements"></a>', "",
            "Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и "
            "[требования практикума](lab-mapping.md#requirements).", ""]


def default_snippet(lang: Language, concept: dict, showcase: dict) -> dict | None:
    sections = lang.example_sections.get(showcase["file"], set())
    for slug in [concept["slug"], *concept.get("legacy_slugs", [])]:
        if slug in sections:
            return {"file": showcase["file"], "section": slug}
    return None


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


# Semantic links are editorial assertions with a scope, not inference rules
# over language cards. In particular prerequisite is pedagogical, not entailment.
RELATIONS = {
    "specializes": ("Частный случай понятия", "Частные случаи", False),
    "contrasts_with": ("Полезный контраст", "Полезный контраст", True),
    "often_confused_with": ("Часто путают", "Часто путают", True),
    "prerequisite": ("Сначала полезно изучить", "Помогает изучить", False),
    "related_to": ("Связано с", "Связано с", True),
}


def load_concept_guide(data_dir: Path, onto: Ontology, report: Report) -> dict:
    guide = load_yaml(data_dir / "concept-guide.yaml")
    if type(guide.get("schema_version")) is not int or guide["schema_version"] != 1:
        raise CatalogError("concept-guide: ожидается schema_version: 1")
    definitions = mapping(guide.get("definitions"), "concept-guide.definitions")
    for cid in sorted(onto.concepts.keys() - definitions.keys()):
        report.error(f"concept-guide: нет определения {cid}")
    for cid, item in definitions.items():
        if cid not in onto.concepts:
            report.error(f"concept-guide: неизвестное понятие {cid}")
        mapping(item, f"concept-guide.{cid}")
        for key in ("definition", "example", "distinction"):
            text(item.get(key), f"concept-guide.{cid}.{key}")
        for number in sequence(item.get("lectures", []), f"concept-guide.{cid}.lectures"):
            if not isinstance(number, str) or not RE_LECTURE.fullmatch(number):
                report.error(f"concept-guide.{cid}.lectures: номер колоды {number!r} — две цифры в кавычках")
    seen = set()
    graphs = {kind: {} for kind in ("specializes", "prerequisite")}
    for edge in sequence(guide.get("relations"), "concept-guide.relations"):
        mapping(edge, "concept-guide.relations[]")
        for key in ("from", "to", "type", "note"):
            text(edge.get(key), f"concept-guide.relations[].{key}")
        source, target, kind = edge["from"], edge["to"], edge["type"]
        if source not in onto.concepts or target not in onto.concepts:
            report.error(f"concept-guide: неизвестный конец связи {source} -> {target}")
        if source == target:
            report.error(f"concept-guide: связь с самим собой {source}")
        if kind not in RELATIONS:
            report.error(f"concept-guide: неизвестный тип связи {kind}")
            continue
        endpoints = tuple(sorted((source, target))) if RELATIONS[kind][2] else (source, target)
        key = (kind, *endpoints)
        if key in seen:
            report.error(f"concept-guide: повторная связь {kind} {source} -> {target}")
        seen.add(key)
        if kind in graphs:
            graphs[kind].setdefault(source, []).append(target)
    for kind, graph in graphs.items():
        visiting, visited = set(), set()

        def visit(node):
            if node in visiting:
                raise CatalogError(f"concept-guide: цикл {kind} у {node}")
            if node in visited:
                return
            visiting.add(node)
            for target in graph.get(node, []):
                visit(target)
            visiting.remove(node)
            visited.add(node)

        for node in graph:
            visit(node)
    question_ids = set()
    for item in sequence(guide.get("questions"), "concept-guide.questions"):
        mapping(item, "concept-guide.questions[]")
        qid = text(item.get("id"), "concept-guide.question.id")
        if not RE_SLUG.fullmatch(qid) or qid in question_ids:
            report.error(f"concept-guide: повторный или некорректный question id {qid}")
        question_ids.add(qid)
        for key in ("question", "answer", "evidence", "gap", "compiler"):
            text(item.get(key), f"concept-guide.{qid}.{key}")
        refs = sequence(item.get("concepts"), f"concept-guide.{qid}.concepts")
        if not refs:
            report.error(f"concept-guide: вопрос {qid} без понятий")
        for cid in refs:
            text(cid, f"concept-guide.{qid}.concepts[]")
            if cid not in onto.concepts:
                report.error(f"concept-guide: вопрос {qid} ссылается на неизвестное понятие {cid}")
    return guide


# ------------------------------------------------ люди, источники и связи
#
# Онтология сайта — не только понятия. Сущности и связи:
#
#   понятие —отношение→ понятие          concept-guide.yaml relations
#   понятие ← язык                       значения в languages/<id>.yaml
#   понятие ← пример                     ссылки из docs/concepts/examples/index.md
#   понятие ← лекция                     people/sources/lectures + заголовки колод
#   человек → язык, понятие, лекция      people.yaml
#   источник → человек, язык, понятие,   sources.yaml
#              лекция, ЛР
#
# Связи хранятся в одном направлении; обратные (у языка — люди и источники,
# у понятия — люди, источники, примеры, лекции) строит генератор.

SOURCE_KINDS = {
    "book": "Книги",
    "article": "Статьи",
    "conference": "Конференции",
    "site": "Сайты и каталоги",
    "documentation": "Документация и инструменты",
    "tool": "Документация и инструменты",
}
RE_LECTURE = re.compile(r"^\d{2}$")
RE_DOI = re.compile(r"^10\.\d{4,9}/\S+$")


@dataclass
class Registry:
    """Люди, источники и внешние связи, общие для всех страниц."""
    people: dict[str, dict] = field(default_factory=dict)
    sources: dict[str, dict] = field(default_factory=dict)
    lectures: dict[str, tuple[str, str]] = field(default_factory=dict)   # номер → (заголовок, slug), опубликованные
    lecture_numbers: set[str] = field(default_factory=set)               # все колоды, включая черновики
    examples: dict[str, list[tuple[str, str]]] = field(default_factory=dict)  # понятие → [(заголовок, якорь)]
    articles: list[dict] = field(default_factory=list)  # опубликованные статьи сада: title, file, languages, concepts

    def articles_of(self, key: str, value: str) -> list[dict]:
        return [a for a in self.articles if value in a.get(key, [])]

    def people_of(self, key: str, value: str) -> list[dict]:
        return [p for p in self.people.values() if value in p.get(key, [])]

    def sources_of(self, key: str, value: str) -> list[dict]:
        return [s for s in self.sources.values() if value in s.get(key, [])]


def load_lectures(slides_dir: Path) -> dict[str, tuple[str, str]]:
    """Опубликованные колоды: номер → (заголовок первого H1, slug файла)."""
    out: dict[str, tuple[str, str]] = {}
    if not slides_dir.is_dir():
        return out
    for path in sorted(slides_dir.glob("*.md")):
        m = re.match(r"^(\d{2})-", path.name)
        if not m or not published(path):
            continue
        title = next((line[2:].strip() for line in path.read_text(encoding="utf-8").split("\n")
                      if line.startswith("# ")), path.stem)
        out[m.group(1)] = (title, path.stem)
    return out


RE_EXAMPLE_SECTION = re.compile(r"^## \d+\. (?P<title>.+?) \{#(?P<anchor>[a-z0-9-]+)\}\s*$")
RE_CONCEPT_REF = re.compile(r"\(\.\./\.\./languages/concepts\.md#(?P<slug>[a-z0-9-]+)\)")


def load_example_links(page: Path, onto: Ontology, report: Report) -> dict[str, list[tuple[str, str]]]:
    """Какие различающие примеры ссылаются на понятие.

    Страница примеров ручная; связь выводится из её ссылок на матрицу,
    чтобы не вести второй список вручную. Битый slug — ошибка данных.
    """
    out: dict[str, list[tuple[str, str]]] = {}
    if not page.is_file() or not published(page):
        return out
    by_slug = onto.by_slug()
    section = None
    for line in page.read_text(encoding="utf-8").split("\n"):
        m = RE_EXAMPLE_SECTION.match(line)
        if m:
            section = (m.group("title"), m.group("anchor"))
            continue
        if line.startswith("## "):
            section = None
        if section is None:
            continue
        for ref in RE_CONCEPT_REF.finditer(line):
            cid = by_slug.get(ref.group("slug"))
            if cid is None:
                report.error(f"{page.name}: ссылка на неизвестное понятие #{ref.group('slug')}")
            elif section not in out.setdefault(cid, []):
                out[cid].append(section)
    return out


def load_articles(garden_dir: Path, onto: Ontology, lang_ids: set[str], report: Report) -> list[dict]:
    """Статьи цифрового сада: связи задаются во front matter статьи.

    `languages: [id…]` и `concepts: [id…]` — ссылки на каталог и онтологию;
    обратные ссылки (у карточки языка и у понятия) строит генератор.
    Неопубликованная статья в обратные ссылки не попадает.
    """
    out = []
    if not garden_dir.is_dir():
        return out
    for path in sorted(garden_dir.glob("*.md")):
        if path.name == "index.md":
            continue
        try:
            meta = page_metadata(path)
        except ValueError as error:
            report.error(str(error))
            continue
        where = f"garden/{path.name}"
        for key, known, what in (("languages", lang_ids, "язык"), ("concepts", onto.concepts.keys(), "понятие")):
            for ref in meta.get(key, []) or []:
                if ref not in known:
                    report.error(f"{where}: неизвестный {what} {ref}")
        if not meta.get("publish"):
            continue
        if not isinstance(meta.get("title"), str) or not meta["title"].strip():
            report.error(f"{where}: у опубликованной статьи нужен title")
            continue
        out.append({"title": meta["title"], "file": path.name,
                    "languages": list(meta.get("languages") or []),
                    "concepts": list(meta.get("concepts") or [])})
    return out


def load_registry(data_dir: Path, onto: Ontology, langs: list[Language], report: Report,
                  guide: dict | None = None,
                  slides_dir: Path = SLIDES_DIR, examples_page: Path = EXAMPLES_PAGE,
                  garden_dir: Path = GARDEN_DIR) -> Registry:
    lang_ids = {lang.id for lang in langs}
    reg = Registry(lectures=load_lectures(slides_dir),
                   lecture_numbers={m.group(1) for p in slides_dir.glob("*.md")
                                    if (m := re.match(r"^(\d{2})-", p.name))},
                   examples=load_example_links(examples_page, onto, report),
                   articles=load_articles(garden_dir, onto, lang_ids, report))
    # Снятая с публикации колода — не ошибка данных: ссылка просто не выводится.
    for cid, item in (guide or {}).get("definitions", {}).items():
        for number in item.get("lectures", []) or []:
            if str(number) not in reg.lecture_numbers:
                report.error(f"concept-guide.{cid}: неизвестная лекция {number}")

    def check_refs(obj: dict, where: str) -> None:
        for key, known, what in (("languages", lang_ids, "язык"),
                                 ("concepts", onto.concepts.keys(), "понятие"),
                                 ("lectures", reg.lecture_numbers, "лекция")):
            refs = sequence(obj.get(key, []), f"{where}.{key}")
            for ref in refs:
                ref = str(ref)
                if key == "lectures" and not RE_LECTURE.fullmatch(ref):
                    report.error(f"{where}.lectures: номер колоды {ref!r} — две цифры в кавычках")
                elif ref not in known:
                    report.error(f"{where}: неизвестный {what} {ref}")
            if len(set(map(str, refs))) != len(refs):
                report.error(f"{where}.{key}: повторы")

    people_raw = load_yaml(data_dir / "people.yaml")
    if people_raw.get("schema_version") != 1:
        raise CatalogError("people.yaml: поддерживается schema_version: 1")
    for person in sequence(people_raw.get("people"), "people.people"):
        mapping(person, "people.people[]")
        pid = text(person.get("id"), "people[].id")
        if not RE_SLUG.fullmatch(pid) or pid in reg.people:
            report.error(f"people: повторный или некорректный id {pid!r}")
        for key in ("name", "ru", "summary"):
            text(person.get(key), f"people.{pid}.{key}")
        optional_texts(person, ("wikidata",), f"people.{pid}")
        if "wikidata" in person and not re.fullmatch(r"Q\d+", person["wikidata"]):
            report.error(f"people.{pid}.wikidata: ожидается Q-идентификатор")
        check_refs(person, f"people.{pid}")
        reg.people[pid] = person

    sources_raw = load_yaml(data_dir / "sources.yaml")
    if sources_raw.get("schema_version") != 1:
        raise CatalogError("sources.yaml: поддерживается schema_version: 1")
    for source in sequence(sources_raw.get("sources"), "sources.sources"):
        mapping(source, "sources.sources[]")
        sid = text(source.get("id"), "sources[].id")
        if not RE_SLUG.fullmatch(sid) or sid in reg.sources or sid in reg.people:
            report.error(f"sources: повторный или некорректный id {sid!r}")
        where = f"sources.{sid}"
        for key in ("title", "note"):
            text(source.get(key), f"{where}.{key}")
        if source.get("kind") not in SOURCE_KINDS:
            report.error(f"{where}.kind={source.get('kind')!r}, допустимо {' | '.join(SOURCE_KINDS)}")
        optional_texts(source, ("venue", "url", "doi", "topic"), where)
        if "doi" in source and not RE_DOI.fullmatch(source["doi"]):
            report.error(f"{where}.doi: ожидается 10.NNNN/…")
        if not source.get("url") and not source.get("doi") and source.get("kind") not in ("book",):
            report.error(f"{where}: нужен url или doi")
        if "year" in source and type(source["year"]) is not int:
            report.error(f"{where}.year: ожидается целый год")
        for author in sequence(source.get("authors", []), f"{where}.authors"):
            text(author, f"{where}.authors[]")
        for pid in sequence(source.get("people", []), f"{where}.people"):
            if pid not in reg.people:
                report.error(f"{where}: неизвестный человек {pid}")
        if not source.get("people") and not source.get("authors") and source.get("kind") in ("book", "article"):
            report.error(f"{where}: у книги или статьи нужны people или authors")
        for lab in sequence(source.get("labs", []), f"{where}.labs"):
            if type(lab) is not int or not 1 <= lab <= 5:
                report.error(f"{where}.labs: номер ЛР от 1 до 5, получено {lab!r}")
        check_refs(source, where)
        reg.sources[sid] = source

    # Автор языка в meta.designers должен быть и в people.yaml со связью
    # на язык: иначе карточка и страница «Люди» расходятся.
    by_name = {p["name"]: p for p in reg.people.values()}
    for lang in langs:
        for name in (lang.raw.get("meta") or {}).get("designers", []) or []:
            person = by_name.get(name)
            if person is None:
                report.error(f"{lang.path.name}: автор {name!r} не описан в people.yaml")
            elif lang.id not in person.get("languages", []):
                report.error(f"people.{person['id']}: нет связи с языком {lang.id}, хотя это автор по карточке")
    return reg


def person_link(person: dict, page: str = "people.md") -> str:
    return f"[{person['ru']}]({page}#{person['id']})"


def source_link(source: dict, page: str = "sources.md") -> str:
    return f"[{source['title']}]({page}#{source['id']})"


def lecture_link(reg: Registry, number: str, prefix: str = "../") -> str:
    title, slug = reg.lectures[number]
    return f"[{number}. {title}]({prefix}lectures/html/{slug}.html)"


def lab_link(number: int, prefix: str = "../") -> str:
    return f"[ЛР {number}]({prefix}labs/index.md#lab-{number})"


def source_authors(source: dict, reg: Registry) -> str:
    names = [reg.people[pid]["ru"] for pid in source.get("people", []) if pid in reg.people]
    return ", ".join(names + list(source.get("authors", [])))


def source_citation(source: dict, reg: Registry) -> str:
    """Библиографическая строка без ссылки на запись в реестре."""
    title = f"*{source['title']}*"
    if source.get("url"):
        title = f"[{source['title']}]({source['url']})"
    parts = [p.rstrip(".") for p in (source_authors(source, reg), title) if p]
    tail = ", ".join(str(x) for x in (source.get("venue"), source.get("year")) if x)
    line = ". ".join(parts) + ("" if parts[-1].endswith((".", "*")) and parts[-1].rstrip("*").endswith(".") else ".")
    if tail:
        line += f" {tail}."
    if source.get("doi"):
        line += f" DOI: [{source['doi']}](https://doi.org/{source['doi']})."
    return line


def concept_link(onto: Ontology, cid: str, page: str = "glossary.md") -> str:
    concept = onto.concepts[cid]
    return f"[{concept['ru']}]({page}#{concept['slug']})"


def concept_lectures(cid: str, guide: dict, reg: Registry) -> list[str]:
    """Лекции, где разбирается понятие (concept-guide.definitions[].lectures).

    Колода может быть снята с публикации — тогда ссылка не выводится.
    """
    return [n for n in guide["definitions"][cid].get("lectures", []) if n in reg.lectures]


def build_glossary(onto: Ontology, guide: dict, reg: Registry | None = None,
                   langs: list[Language] | None = None) -> str:
    reg = reg or Registry()
    langs = langs or []
    out = [GENERATED_NOTICE, "", "# Понятия", "",
           "Словарь онтологии. Определения описывают понятия, а не приписывают свойства всем языкам. "
           "У каждого понятия — отношения с другими понятиями и переходы к языкам, "
           "[различающим примерам](../concepts/examples/index.md), слайдам лекций, "
           "[людям](people.md) и [источникам](sources.md). "
           "[Сравнение языков](concepts.md) содержит конкретные контекстные утверждения; "
           "[проверочные вопросы](questions.md) показывают применение словаря и пробелы данных.", "",
           "## Как читать связи { #relations }", "",
           "- **Частный случай:** A → B означает, что механизм A рассматривается как частный случай B, не наоборот.",
           "- **Полезный контраст:** два понятия сравниваются по явно указанному признаку; это не запрет их совместного использования.",
           "- **Часто путают:** сходство слов или синтаксиса создаёт типичную ошибку; связь не означает тождества.",
           "- **Сначала полезно изучить:** A → B рекомендует изучить B перед A. Это педагогическая рекомендация, не логическая необходимость.",
           "- **Связано с:** содержательная связь без утверждения включения или зависимости.", "",
           "Симметричные связи записаны один раз и показаны с обеих сторон. "
           "Обратная связь «частные случаи» и «помогает изучить» строится автоматически. "
           "Из связей не выводятся новые свойства языков и не вычисляются транзитивные рекомендации.", "",
           f"**{len(guide['definitions'])} определений · {len(guide['relations'])} связей · "
           f"{len(guide['questions'])} вопросов.**", "", "## Разделы", ""]
    for cat in onto.categories:
        out.append(f"- [{cat['ru']}](#{cat['id']})")
    for cat in onto.categories:
        out += ["", f"## {cat['ru']} {{ #{cat['id']} }}", ""]
        for c in cat["concepts"]:
            cid = c["id"]
            definition = guide["definitions"][cid]
            out += [f"### {c['ru']} {{ #{c['slug']} }}", "",
                    f"*{c.get('en', '')}* · `{cid}` · " + concept_link(onto, cid, "concepts.md"), "",
                    definition["definition"], "", "**Пример.** " + definition["example"], "",
                    "**Граница понятия.** " + definition["distinction"], "", "**Связи:**", ""]
            for edge in guide["relations"]:
                if cid not in (edge["from"], edge["to"]):
                    continue
                forward = cid == edge["from"]
                other = edge["to"] if forward else edge["from"]
                label = RELATIONS[edge["type"]][0 if forward else 1]
                out.append(f"- {label}: {concept_link(onto, other)} — {edge['note']}")
            in_langs = [l for l in langs if cid in (l.raw.get("concepts") or {})]
            if in_langs:
                out += ["", "**В языках:** " + ", ".join(
                    f"[{l.raw['meta']['ru']}]({lang_page(l)}#{c['slug']})" for l in in_langs)]
            if reg.examples.get(cid):
                out += ["", "**Различающие примеры:** " + ", ".join(
                    f"[{title}](../concepts/examples/index.md#{anchor})"
                    for title, anchor in reg.examples[cid])]
            articles = reg.articles_of("concepts", cid)
            if articles:
                out += ["", "**Статьи сада:** " + ", ".join(
                    f"[{a['title']}](../garden/{a['file']})" for a in articles)]
            lectures = concept_lectures(cid, guide, reg)
            if lectures:
                out += ["", "**Слайды лекций:** " + ", ".join(lecture_link(reg, n) for n in lectures)]
            questions = [q for q in guide["questions"] if cid in q["concepts"]]
            if questions:
                out += ["", "**Проверить понимание:** " + "; ".join(
                    f"[{q['question']}](questions.md#{q['id']})" for q in questions)]
            people = reg.people_of("concepts", cid)
            if people:
                out += ["", "**Люди:** " + ", ".join(person_link(p) for p in people)]
            sources = reg.sources_of("concepts", cid)
            if sources or c.get("sources"):
                parts = [source_link(s) for s in sources]
                if c.get("sources"):
                    parts.append(render_sources(c["sources"]))
                out += ["", "**Источники:** " + "; ".join(parts)]
            out.append("")
    return "\n".join(out)


def build_people(onto: Ontology, reg: Registry, langs: list[Language]) -> str:
    names = {l.id: l for l in langs}
    out = [GENERATED_NOTICE, "", "# Люди", "",
           "Авторы языков каталога и формальной теории, на которую опирается курс. "
           "Для каждого человека — вклад, языки, [понятия](glossary.md), слайды лекций и "
           "[источники](sources.md). Связи проверяемы: у записи есть идентификатор Wikidata, "
           "а у источника — публикация. Это не биографии и не исчерпывающий список.", ""]
    groups = [
        ("Авторы языков каталога", [p for p in reg.people.values() if p.get("languages")]),
        ("Теория и трансляция", [p for p in reg.people.values() if not p.get("languages")]),
    ]
    for title, people in groups:
        if not people:
            continue
        out += [f"## {title}", ""]
        for p in people:
            out += [f"### {p['ru']} {{ #{p['id']} }}", ""]
            line = f"*{p['name']}*"
            if p.get("wikidata"):
                line += f" · [Wikidata {p['wikidata']}](https://www.wikidata.org/wiki/{p['wikidata']})"
            out += [line, "", p["summary"].strip(), ""]
            published_langs = [names[lid] for lid in p.get("languages", []) if lid in names]
            if published_langs:
                out.append("- **Языки:** " + ", ".join(
                    f"[{l.raw['meta']['ru']}]({lang_page(l)})" for l in published_langs))
            if p.get("concepts"):
                out.append("- **Понятия:** " + ", ".join(concept_link(onto, cid) for cid in p["concepts"]))
            lectures = [n for n in p.get("lectures", []) if n in reg.lectures]
            if lectures:
                out.append("- **Слайды лекций:** " + ", ".join(lecture_link(reg, n) for n in lectures))
            sources = reg.sources_of("people", p["id"])
            if sources:
                out.append("- **Источники:** " + "; ".join(source_link(s) for s in sources))
            out.append("")
    return "\n".join(out)


def build_sources(onto: Ontology, reg: Registry, langs: list[Language]) -> str:
    names = {l.id: l for l in langs}
    out = [GENERATED_NOTICE, "", "# Источники", "",
           "Книги, статьи, конференции, сайты и инструменты, на которые опираются курс и онтология. "
           "У каждого источника указано, зачем его читать и к чему он относится: "
           "[людям](people.md), языкам, [понятиям](glossary.md), слайдам лекций и лабораторным работам.", ""]
    order: list[str] = []
    for kind in SOURCE_KINDS.values():
        if kind not in order:
            order.append(kind)
    for group in order:
        items = [s for s in reg.sources.values() if SOURCE_KINDS[s["kind"]] == group]
        if not items:
            continue
        out += [f"## {group}"]
        topic = None
        if not items[0].get("topic"):
            out.append("")
        for s in items:
            if s.get("topic") and s["topic"] != topic:
                topic = s["topic"]
                out += ["", f"### {topic}", ""]
            out.append(f'- <a id="{s["id"]}"></a>' + source_citation(s, reg) + " " + s["note"].strip())
            links = []
            people = [reg.people[pid] for pid in s.get("people", []) if pid in reg.people]
            if people:
                links.append("люди: " + ", ".join(person_link(p) for p in people))
            ls = [names[lid] for lid in s.get("languages", []) if lid in names]
            if ls:
                links.append("языки: " + ", ".join(f"[{l.raw['meta']['ru']}]({lang_page(l)})" for l in ls))
            if s.get("concepts"):
                links.append("понятия: " + ", ".join(concept_link(onto, cid) for cid in s["concepts"]))
            lectures = [n for n in s.get("lectures", []) if n in reg.lectures]
            if lectures:
                links.append("лекции: " + ", ".join(lecture_link(reg, n) for n in lectures))
            if s.get("labs"):
                links.append("практикум: " + ", ".join(lab_link(n) for n in s["labs"]))
            if links:
                out.append("    <br>Связи — " + "; ".join(links) + ".")
        out.append("")
    return "\n".join(out)


def build_questions(onto: Ontology, guide: dict) -> str:
    out = [GENERATED_NOTICE, "", "# Вопросы, на которые должна отвечать онтология", "",
           "Это проверка полезности модели, а не тест с единственным словом-ответом. "
           "Для каждого вопроса указаны понятия, содержательный ответ, основания и "
           "то, что ещё нельзя получить из структурированных данных. "
           "Ответы написаны автором, а не автоматически выведены из матрицы.", "",
           "Не смешивайте пробел данных, неточное определение и отсутствие нужной оси: "
           "для каждого требуется своё исправление. Контекст реализации, профиля и версии "
           "нужно проверять на [карточке языка](index.md).", "",
           "[Словарь и типы связей](glossary.md) · [Различающие примеры](../concepts/examples/index.md)", ""]
    for item in guide["questions"]:
        out += [f"## {item['question']} {{ #{item['id']} }}", "",
                "**Понятия:** " + ", ".join(concept_link(onto, cid) for cid in item["concepts"]), "",
                "**Ответ.** " + item["answer"], "",
                "**Основания и пример.** " + item["evidence"], "",
                "**Предел текущей модели.** " + item["gap"], "",
                "**Для реализации языка.** " + item["compiler"], ""]
    return "\n".join(out)


def build_language(lang: Language, onto: Ontology, langs: list[Language],
                   reg: Registry | None = None) -> str:
    r = lang.raw
    meta = r["meta"]
    reg = reg or Registry()
    out: list[str] = [GENERATED_NOTICE, "", f"# {meta['ru']}", "", meta["summary"].strip(), "",
                      f"*Карточка {completeness_label(lang, onto)}* — "
                      "[как читать отметку](index.md#как-читать-карточку).", ""]

    # --- метаданные
    out += ["## Метаданные { #meta }", ""]
    rows = []
    if "appeared" in meta:
        ap = meta["appeared"]
        val = ap["value"] if isinstance(ap, dict) else ap
        src = render_sources(ap.get("sources")) if isinstance(ap, dict) else ""
        rows.append(("Год появления", f"{val}" + (f" — {src}" if src else "")))
    if meta.get("designers"):
        by_name = {p["name"]: p for p in reg.people.values()}
        rows.append(("Авторы", ", ".join(
            person_link(by_name[n]) if n in by_name else n for n in meta["designers"])))
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

    # --- статьи цифрового сада об идеях языка
    articles = reg.articles_of("languages", lang.id)
    if articles:
        out += ["## Статьи { #articles }", ""]
        out += [f"- [{a['title']}](../garden/{a['file']})" for a in articles]
        out.append("")

    # --- люди: авторы и участники, связанные с языком в people.yaml
    people = reg.people_of("languages", lang.id)
    if people:
        out += ["## Люди { #people }", ""]
        out += [f"- {person_link(p)} — {p['summary'].strip()}" for p in people]
        out.append("")

    # --- публикации: собственные записи карточки и источники онтологии
    ontology_sources = reg.sources_of("languages", lang.id)
    if r.get("publications") or ontology_sources:
        out += ["## Публикации { #publications }", ""]
        for pub in r.get("publications", []):
            authors = ", ".join(pub.get("authors", []))
            title = pub["title"]
            if pub.get("url"):
                title = f"[{title}]({pub['url']})"
            tail = ", ".join(str(x) for x in (pub.get("venue"), pub.get("year")) if x)
            out.append(f"- {authors}. *{title}*." + (f" {tail}." if tail else ""))
        for source in ontology_sources:
            out.append(f"- {source_citation(source, reg)} {source['note'].strip()} "
                       f"([в источниках](sources.md#{source['id']}))")
        out.append("")

    # --- концепции
    out += ["## Концепции { #concepts }", "",
            "Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.", ""]
    out += lab_mapping_links()
    if r.get("profiles"):
        out += ["Профили описания:", ""]
        out += [f"- **{name}** — {description}" for name, description in r["profiles"].items()]
        out.append("")
    concepts = r.get("concepts") or {}
    showcase = next((e for e in r.get("examples", []) if e.get("role") == "showcase"), None)
    for cat in onto.categories:
        cat_concepts = [c for c in cat.get("concepts", []) if c["id"] in concepts]
        if not cat_concepts:
            continue
        out += [f"### {cat['ru']} {{ #{cat['id']} }}", ""]
        for c in cat_concepts:
            entries = concepts[c["id"]]
            out += legacy_anchors(c)
            out += [f"#### {c['ru']} {{ #{c['slug']} }}", ""]
            out.append(f"*{c.get('en', '')}* · [в онтологии](concepts.md#{c['slug']})")
            out.append("")
            for e in entries:
                line = f"- **{value_label(onto, c['id'], e, lang)}**"
                extras = []
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
            snippet = default_snippet(lang, c, showcase) if showcase else None
            snippets = overrides or ([snippet] if snippet and any(e["value"] != "n/a" for e in entries) else [])
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


# Полнота карточки — вычисляемая отметка, а не текст в summary: она не
# устаревает, когда в карточку добавляют пример или грамматику.
COMPLETENESS = (
    ("concepts", "понятия"),
    ("showcase", "пример"),
    ("grammar", "грамматика"),
    ("assessment", "оценка"),
)


def completeness(lang: Language, onto: Ontology) -> tuple[list[str], int, int]:
    """Имеющиеся части карточки и число заполненных понятий онтологии."""
    r = lang.raw
    filled = len([cid for cid in (r.get("concepts") or {}) if cid in onto.concepts])
    parts = {
        "concepts": filled > 0,
        "showcase": any(e.get("role") == "showcase" for e in r.get("examples", []) or []),
        "grammar": bool((r.get("grammar") or {}).get("fragments")),
        "assessment": bool(r.get("assessment")),
    }
    return [label for key, label in COMPLETENESS if parts[key]], filled, len(onto.concepts)


def completeness_label(lang: Language, onto: Ontology) -> str:
    parts, filled, total = completeness(lang, onto)
    level = "полная" if len(parts) == len(COMPLETENESS) else "сравнительная"
    return f"{level}: {filled}/{total} понятий" + (
        "; " + ", ".join(p for p in parts if p != "понятия") if len(parts) > 1 else "")


def build_index(langs: list[Language], onto: Ontology) -> str:
    out = [GENERATED_NOTICE, "", "# Каталог языков программирования", "",
           "Независимый справочник языков программирования: [понятия онтологии](glossary.md) "
           "общие для разных исторических семейств и парадигм — "
           "от императивных и объектно-ориентированных до функциональных и логических языков. "
           "Карточки уточняют свойства по версиям, профилям, реализациям и слоям. "
           "Грамматики и примеры дополняют описание там, где они доступны. "
           "Языки упорядочены по году появления. "
           "[Соответствия лабораторным работам](lab-mapping.md) вынесены отдельно.", "",
           "| Язык | Появился | Авторы | Типизация | Память | Ошибки | Полнота карточки |",
           "|---|---|---|---|---|---|---|"]
    for lang in langs:
        m = lang.raw["meta"]
        year = appeared_year(lang.raw)
        def joined(cid: str) -> str:
            return "; ".join(value_label(onto, cid, e, lang) for e in (lang.raw.get("concepts") or {}).get(cid, []))
        out.append(f"| [{m['ru']}]({lang_page(lang)}) | {year or ''} | {md_escape(', '.join(m.get('designers', [])))} "
                   f"| {md_escape(joined('typing.checking'))} | {md_escape(joined('memory.management'))} "
                   f"| {md_escape(joined('errors.model'))} | {completeness_label(lang, onto)} |")
    out += ["", "<div class=\"grid cards\" markdown>", ""]
    for lang in langs:
        m = lang.raw["meta"]
        year = appeared_year(lang.raw)
        title = f"{m['ru']}" + (f" · {year}" if year else "")
        out += [f"- **[{title}]({lang_page(lang)})**", "", f"    {m['summary'].strip()}", "",
                f"    *Карточка {completeness_label(lang, onto)}.*", ""]
    out += ["- **[Сравнение языков](concepts.md)**", "",
            "    Матрица «понятие × язык» по всем карточкам.", "",
            "- **[Соответствия практикуму](lab-mapping.md)**", "",
            "    Учебные пункты и связанные независимые понятия.", "", "</div>", ""]
    out += ["## Как читать карточку", "",
            "- **Полнота** — вычисляется по данным: сколько понятий онтологии заполнено и есть ли "
            "пример-витрина, фрагменты грамматики и оценка по критериям лекции 20. "
            "«Сравнительная» карточка описывает значения понятий без примеров кода; "
            "это не утверждение о полноте описания самого языка.",
            "- **Концепции** — значения из закрытых перечислений; у значения могут быть версия, с которой "
            "оно появилось, слой, профиль, реализация, область применимости и примечание. "
            "Отсутствующая запись означает неизвестность; false — отрицание, n/a — неприменимость с пояснением.",
            "- **Грамматика** — фрагменты community-грамматик grammars-v4; официальная спецификация "
            "каждого языка записана в своей нотации, ссылка дана.",
            "- **Пример-витрина** — необязательная программа с прокомментированными конструкциями.", "",
            "Как добавить язык — `docs/languages/_data/README.md` в репозитории курса.", ""]
    return "\n".join(out)


def build_concepts(langs: list[Language], onto: Ontology, report: Report, guide: dict | None = None) -> str:
    out = [GENERATED_NOTICE, "", "# Сравнение языков", "",
           "Матрица «понятие × язык»: значения [понятий онтологии](glossary.md) для всех "
           "языков каталога в порядке появления. Значение в ячейке — из "
           "закрытого перечисления; в скобках — версии и контекст: слой, профиль, реализация и область "
           "применимости. since включительно, until исключительно. Подробности "
           "(примечания, источники, код) — на карточке языка по ссылке в ячейке. "
           "«неприменимо (n/a)» требует пояснения; «нет» — булево false; пустая ячейка — данных нет.", ""]
    out += lab_mapping_links()
    out += ["[Понятия: определения и связи](glossary.md) · "
            "[Проверочные вопросы](questions.md) · [Люди](people.md) · [Источники](sources.md)", ""]
    out += ["Практическое чтение: [различающие примеры для 15 языков](../concepts/examples/index.md) "
            "— код, ожидаемый результат и статус проверки.", ""]
    out += ["## Покрытие { #coverage }", "",
            "Доля значений перечислений, для которых в каталоге есть хотя бы один язык. "
            "Пробелы покрытия информационные; возможные примеры указаны в скобках, если известны.", "",
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
                cells.append(f"[{md_escape(cell)}]({lang_page(l)}#{c['slug']})")
            out.append(f"| [{c['ru']}](#{c['slug']}) | " + " | ".join(cells) + " |")
        out.append("")
        for c in cat.get("concepts", []):
            out += legacy_anchors(c)
            out += [f"### {c['ru']} {{ #{c['slug']} }}", ""]
            desc = f"*{c.get('en', '')}*"
            if c.get("aliases"):
                desc += " · также: " + ", ".join(c["aliases"])
            out += [desc, ""]
            if guide:
                out += [guide["definitions"][c["id"]]["definition"], "",
                        "[Пример, границы понятия и связи](glossary.md#" + c["slug"] + ")", ""]
            if c.get("note"):
                out += [c["note"].strip(), ""]
            if c.get("sources"):
                out += ["Источники определения: " + render_sources(c["sources"]), ""]
            if c.get("kind") == "choice":
                for vid, v in onto.values[c["id"]].items():
                    line = f"- `{vid}` — **{v['ru']}** (*{v.get('en', '')}*)"
                    if v.get("note"):
                        line += f": {v['note']}"
                    if v.get("sources"):
                        line += " — " + render_sources(v["sources"])
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


def build_lab_mapping(mappings: list[dict], onto: Ontology) -> str:
    out = [GENERATED_NOTICE, "", "# Соответствия практикуму", "",
           "Учебные пункты ссылаются на [независимую онтологию](concepts.md), "
           "но не определяют её категории и допустимые значения.", "",
           '<a id="variants"></a>', "",
           "[Варианты заданий](../labs/index.md#varianty): " + ", ".join(
               f"[{item['id']}](#{mapping_anchor(item['id'])})" for item in mappings
               if item["id"].startswith("variants.")), "",
           '<a id="requirements"></a>', "",
           "Требования практикума: " + ", ".join(
               f"[{item['id']}](#{mapping_anchor(item['id'])})" for item in mappings
               if item["id"].startswith("req.")), ""]
    for item in mappings:
        out += [f"## {item['id']}. {item['title']} {{ #{mapping_anchor(item['id'])} }}", ""]
        out += [f"- [{onto.concepts[cid]['ru']}](concepts.md#{onto.concepts[cid]['slug']})"
                for cid in item["concepts"]]
        out += ["", item["note"], ""]
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
        guide = load_concept_guide(data_dir, onto, report)
        mappings = load_lab_mapping(data_dir, onto, report)
        langs = load_languages(data_dir, report)
        if not langs:
            report.error(f"{data_dir / 'languages'}: нет ни одного языка")
        for lang in langs:
            try:
                validate_language(lang, onto, data_dir, report)
            except CatalogError as e:
                report.error(str(e))
        if not report.errors:
            validate_coverage(onto, langs, report)
        registry = load_registry(data_dir, onto, langs, report, guide)
    except CatalogError as e:
        report.error(str(e))

    for w in report.warnings:
        print(f"  предупреждение: {w}")
    for cat, (cov, tot) in report.coverage.items():
        print(f"  покрытие {cat}: {cov}/{tot} ({cov / tot:.0%})")
        if report.uncovered.get(cat):
            print(f"    пробелы: {', '.join(report.uncovered[cat])}")
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
        out_dir / "concepts.md": page_frontmatter(out_dir / "concepts.md") + build_concepts(public_langs, onto, public_report, guide),
        out_dir / "glossary.md": page_frontmatter(out_dir / "glossary.md") + build_glossary(onto, guide, registry, public_langs),
        out_dir / "questions.md": page_frontmatter(out_dir / "questions.md") + build_questions(onto, guide),
        out_dir / "people.md": page_frontmatter(out_dir / "people.md") + build_people(onto, registry, public_langs),
        out_dir / "sources.md": page_frontmatter(out_dir / "sources.md") + build_sources(onto, registry, public_langs),
        out_dir / "lab-mapping.md": page_frontmatter(out_dir / "lab-mapping.md") + build_lab_mapping(mappings, onto),
    }
    for lang in langs:
        pages[out_dir / lang_page(lang)] = (frontmatter({"publish": publication_flag(lang.raw, lang.path)})
                                            + build_language(lang, onto, langs, registry))

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
