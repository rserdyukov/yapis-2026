"""Единое правило публикации для MkDocs, генераторов и Marp."""

from pathlib import Path

import yaml


class PublicationLoader(yaml.SafeLoader):
    """Не допускаем двух противоречивых указаний publish в одном объекте."""

    def construct_mapping(self, node, deep=False):
        count = sum(key.value == "publish" for key, _ in node.value)
        if count > 1:
            raise yaml.YAMLError("publish указан несколько раз")
        return super().construct_mapping(node, deep=deep)


def load_publication_yaml(text: str, source: object) -> dict:
    try:
        data = yaml.load(text, Loader=PublicationLoader)
    except yaml.YAMLError as error:
        raise ValueError(f"{source}: некорректный YAML: {error}") from error
    if data is None:
        data = {}
    if not isinstance(data, dict):
        raise ValueError(f"{source}: ожидается YAML-объект")
    return data


def metadata(path: Path) -> dict:
    """Читаем только начальный YAML-блок, не разделители слайдов Marp."""
    if not path.exists():
        return {}
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    if not lines or lines[0].rstrip() != "---":
        return {}
    for end in range(1, len(lines)):
        if lines[end].rstrip() in ("---", "..."):
            data = load_publication_yaml("\n".join(lines[1:end]), path)
            publication_flag(data, path)
            return data
    raise ValueError(f"{path}: не закрыт YAML front matter")


def publication_flag(data: dict, source: object) -> bool:
    value = data.get("publish", False)
    if type(value) is not bool:
        raise ValueError(f"{source}: publish должен быть true или false без кавычек")
    return value


def published(path: Path) -> bool:
    return publication_flag(metadata(path), path)


def frontmatter(data: dict) -> str:
    return "---\n" + yaml.safe_dump(data, allow_unicode=True, sort_keys=False) + "---\n\n"


def page_frontmatter(path: Path) -> str:
    """Ручные метаданные обёртки сохраняются при пересборке её тела."""
    data = metadata(path)
    data.setdefault("publish", False)
    return frontmatter(data)
