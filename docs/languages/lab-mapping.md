---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Соответствия практикуму

Учебные пункты ссылаются на [независимую онтологию](concepts.md), но не определяют её категории и допустимые значения.

<a id="variants"></a>

[Варианты заданий](../labs/index.md#varianty): [variants.1](#variants-1), [variants.2](#variants-2), [variants.3](#variants-3), [variants.4](#variants-4), [variants.5](#variants-5), [variants.6](#variants-6), [variants.7](#variants-7), [variants.8](#variants-8), [variants.9](#variants-9)

<a id="requirements"></a>

Требования практикума: [req.4](#req-4), [req.7.2.until](#req-7-2-until), [req.7.2.do_while](#req-7-2-do_while), [req.7.3](#req-7-3), [req.8.2](#req-8-2)

## variants.1. Объявление переменных { #variants-1 }

- [Введение связывания](concepts.md#bindings-introduction)
- [Аннотации типов](concepts.md#typing-annotations)
- [Вывод статических типов](concepts.md#typing-inference)

Явное введение имени, наличие аннотации и вывод типа независимы: Java var и Rust let вводят имя явно даже без написанного типа.

## variants.2. Преобразование типов { #variants-2 }

- [Преобразования типов](concepts.md#typing-conversions)

Язык может поддерживать и явные преобразования, и ограниченные coercions; допустимость и потеря точности описываются для конкретных типов.

## variants.3. Оператор присваивания { #variants-3 }

- [Формы присваивания и связывания](concepts.md#bindings-assignment)
- [Изменяемость связывания](concepts.md#bindings-mutation)

Одиночное и распаковывающее присваивание отделены от возможности перепривязки. Унификация Prolog и неизменяемые определения Haskell не являются обычным изменяющим присваиванием.

## variants.4. Структуры, ограничивающие область видимости { #variants-4 }

- [Конструкции областей видимости](concepts.md#scope-constructs)
- [Правило разрешения имён](concepts.md#scope-resolution)
- [Сокрытие имён](concepts.md#scope-shadowing)

Какая конструкция вводит область, как разрешаются имена и разрешено ли скрывать внешнее имя — разные вопросы; область класса или comprehension не сводится к подпрограмме.

## variants.5. Маркер блочного оператора { #variants-5 }

- [Границы синтаксических групп](concepts.md#syntax-blocks)
- [Конструкции областей видимости](concepts.md#scope-constructs)

Синтаксическая группа может не создавать область видимости. Учитываются явные разделители, отступы и S-выражения без требования блочного оператора во всех языках.

## variants.6. Условные операторы { #variants-6 }

- [Условный выбор](concepts.md#control-selection)
- [Выбор по значению switch/case](concepts.md#control-switch)
- [Сопоставление с образцом](concepts.md#control-pattern-matching)

Условный выбор, switch по значениям и структурное сопоставление учитываются независимо; Python match не означает наличие отдельного switch.

## variants.7. Перегрузка подпрограмм { #variants-7 }

- [Перегрузка по сигнатуре](concepts.md#subprograms-overloading)
- [Диспетчеризация вызовов](concepts.md#abstraction-dispatch)
- [Контракты полиморфизма](concepts.md#abstraction-contracts)

Перегрузка по сигнатуре отличается от динамической диспетчеризации, трейтов Rust, классов типов Haskell и generic functions Common Lisp.

## variants.8. Передача параметров в подпрограмму { #variants-8 }

- [Связывание параметров](concepts.md#subprograms-parameter-passing)
- [Передача и разделение владения](concepts.md#memory-transfer)
- [Стратегия вычисления](concepts.md#evaluation-strategy)

Связывание параметра отделено от копирования, перемещения владения и заимствования. Rust передаёт значения, включая ссылки; C# out — ссылка для выходного параметра, не обязательно copy-out. Для нестрогих языков отдельно учитывается вычисление аргумента.

## variants.9. Допустимое место объявления подпрограмм { #variants-9 }

- [Место определения подпрограмм](concepts.md#subprograms-placement)
- [Вложенные именованные подпрограммы](concepts.md#subprograms-nesting)
- [Захват окружения](concepts.md#subprograms-closures)

Размещение, вложенность именованной функции и захват окружения независимы: вложенная Rust fn не захватывает окружение, Java lambda захватывает его без вложенного метода.

## req.4. Ввод-вывод { #req-4 }

- [Интерфейс ввода-вывода](concepts.md#resources-io)
- [Контроль эффектов](concepts.md#evaluation-effects)
- [Представление и передача ошибок](concepts.md#errors-model)

read/write сопоставляются с API языка или библиотеки; эффект ввода-вывода (например IO в Haskell) и канал ошибки описываются отдельно.

## req.7.2.until. Цикл until { #req-7-2-until }

- [Цикл до истинности условия](concepts.md#control-until)

Until прекращает повторение при истинном условии. Предусловие while-not может выполнить тело ноль раз; постусловие repeat-until выполняет тело хотя бы раз. Учебную форму нужно уточнять по положению проверки.

## req.7.2.do_while. Цикл do-while { #req-7-2-do_while }

- [Цикл do-while с постусловием](concepts.md#control-do-while)
- [Цикл до истинности условия](concepts.md#control-until)

Do-while проверяет условие после тела и продолжает при истине; repeat-until также имеет постусловие, но противоположную полярность. Эмуляция через loop/break не означает наличие отдельной конструкции.

## req.7.3. Цикл for { #req-7-3 }

- [Формы итерации](concepts.md#control-iteration)

C-style for, обход итератора, comprehension и функции обхода представляют разные механизмы; range не превращает Python for в трёхчастный C-style for.

## req.8.2. Глобальная область видимости для переменных { #req-8-2 }

- [Связывания верхнего уровня](concepts.md#scope-globals)
- [Правило разрешения имён](concepts.md#scope-resolution)
- [Изменяемость связывания](concepts.md#bindings-mutation)

Различаются глобальные переменные, модульные связывания и статические члены; доступность имени не означает изменяемость или динамическую область видимости.
