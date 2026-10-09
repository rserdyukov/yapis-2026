"""Точка входа: python3 -B <путь>/labgen <каталог работы> или python3 -m labgen."""

import sys

if not __package__:
    # Запуск каталога как скрипта: относительные импорты пакета требуют,
    # чтобы пакет импортировался по имени из родительского каталога.
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from labgen.cli import main
else:
    from .cli import main

sys.exit(main())
