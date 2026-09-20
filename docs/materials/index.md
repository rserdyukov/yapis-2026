---
publish: true
---

# Книги и ресурсы

## Литература

- Орлов С. А. *Теория и практика языков программирования.* СПб.: Питер, 2013.
- Ахо А., Сети Р., Ульман Дж. *Компиляторы: принципы, технологии и
  инструменты.* Пер. с англ. М.: Вильямс, 2001.
- Себеста Р. У. *Основные концепции языков программирования*, 5-е изд.
  Пер. с англ. М.: Вильямс, 2001.
- Страуструп Б. *Дизайн и эволюция C++.* Пер. с англ. М.: ДМК Пресс;
  СПб.: Питер, 2006.
- Непейвода Н. Н. *Стили и методы программирования*, 2016.

## Инструменты

### ANTLR

Генератор лексических и синтаксических анализаторов — основной инструмент
практикума, начиная с [лабораторной работы 2](../labs/index.md).

- [antlr.org](https://www.antlr.org/) — документация и загрузка
- [lab.antlr.org](http://lab.antlr.org/) — отладка грамматики в браузере,
  без установки
- [Коллекция готовых грамматик](https://github.com/antlr/grammars-v4) —
  полезна как справочник по стилю, но не как источник для копирования

### Целевые платформы

Какая платформа у вас — определяется [вариантом](../labs/variants.md),
раздел «Варианты целевого кода».

| Целевой код | Документация | Инструменты |
|---|---|---|
| Байт-код JVM | [JVM Specification](https://docs.oracle.com/javase/specs/jvms/se21/html/) | [Jasmin](https://jasmin.sourceforge.net/), [ASM](https://asm.ow2.io/) |
| .NET CIL | [ECMA-335](https://ecma-international.org/publications-and-standards/standards/ecma-335/) | `ilasm`, [Mono.Cecil](https://github.com/jbevain/cecil) |
| LLVM IR | [LLVM Language Reference](https://llvm.org/docs/LangRef.html) | `llvm-as`, `lli` |
| Байт-код CPython | [модуль `dis`](https://docs.python.org/3/library/dis.html) | `dis`, [`bytecode`](https://pypi.org/project/bytecode/) |
| WAT / WebAssembly | [WebAssembly Specification](https://webassembly.github.io/spec/core/) | [WABT](https://github.com/WebAssembly/wabt), [wasmtime](https://wasmtime.dev/) |

## Теория

- [Crafting Interpreters](https://craftinginterpreters.com/) — Robert
  Nystrom, бесплатная онлайн-книга. Хороший разбор устройства
  интерпретатора и компилятора на практике.
- [Godbolt Compiler Explorer](https://godbolt.org/) — смотреть, во что
  компилируется код на разных языках и платформах. Полезно при работе над
  [лабораторной работой 5](../labs/index.md).
