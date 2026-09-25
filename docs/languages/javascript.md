---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# JavaScript

JavaScript описан здесь как ECMAScript 2024 с динамическими типами, прототипными объектами и функциями первого класса. Ввод-вывод предоставляется хостом (например, браузером или Node.js), а не самим ECMAScript.

*Карточка сравнительная: 34/74 понятий* — [как читать отметку](index.md#как-читать-карточку).

## Метаданные { #meta }

| | |
|---|---|
| Год появления | 1995 — [Wikidata P571](https://www.wikidata.org/wiki/Q2005) (получено 2026-09-24) |
| Авторы | [Брендан Эйх](people.md#eich) |
| Организации | Netscape, Ecma International TC39 |
| Сайт | <https://tc39.es/> |
| Спецификация | <https://262.ecma-international.org/15.0/> |
| Внешние каталоги | [Wikidata Q2005](https://www.wikidata.org/wiki/Q2005) |

## Статьи { #articles }

- [JavaScript: цена обратной совместимости](../garden/javascript-compatibility.md)
- [Lua: метатаблицы, язык как конструктор](../garden/lua-metatables.md)
- [Smalltalk: всё есть сообщение](../garden/smalltalk-messages.md)

## Люди { #people }

- [Брендан Эйх](people.md#eich) — Создал первую реализацию JavaScript в Netscape в 1995 году и участвовал в стандартизации ECMAScript.

## Публикации { #publications }

- Брендан Эйх, Allen Wirfs-Brock. *JavaScript: The First 20 Years*. Proc. ACM Program. Lang. 4, HOPL IV, 2020. DOI: [10.1145/3386327](https://doi.org/10.1145/3386327). Создание JavaScript и развитие стандарта ECMAScript. ([в источниках](sources.md#hopl-javascript))

## Концепции { #concepts }

Значения — из [общей онтологии каталога](concepts.md); там же матрица по всем языкам.

<a id="variants"></a>
<a id="requirements"></a>

Учебные соответствия: [варианты заданий](lab-mapping.md#variants) и [требования практикума](lab-mapping.md#requirements).

Профили описания:

- **es2024** — ECMA-262, 15-я редакция (ECMAScript 2024); общий базовый профиль, если не указан strict или sloppy.
- **strict** — ECMAScript 2024, strict mode: модули и тела классов всегда строгие, скрипты/функции могут включить use strict.
- **sloppy** — ECMAScript 2024, нестрогий код Script/функций; не применяется к модулям и телам классов.

### Имена и связывание { #bindings }

<a id="variants-1"></a>

#### Введение связывания { #bindings-introduction }

*Binding introduction* · [в онтологии](concepts.md#bindings-introduction)

- **Явное объявление (layer: language, profile: es2024)** — let, const, var, объявления функций и классов.
- **Связывание образцом (layer: language, profile: es2024)** — Деструктурирующие объявления и параметры.
- **Связывание присваиванием (layer: language, profile: sloppy, applies_to: присваивание неразрешимому имени)** — В обычном хосте может создать свойство глобального объекта, а не лексическое let-связывание. В strict mode такое присваивание вызывает ReferenceError. ([ECMA-262 2024, PutValue](https://262.ecma-international.org/15.0/#sec-putvalue))

#### Изменяемость связывания { #bindings-mutation }

*Binding mutability* · [в онтологии](concepts.md#bindings-mutation)

- **Перепривязываемое (layer: language, profile: es2024, applies_to: let и var)**
- **Неизменяемое (layer: language, profile: es2024, applies_to: const)** — const запрещает перепривязку; объект, на который ссылается значение, может быть изменяемым.

<a id="variants-3"></a>

#### Формы присваивания и связывания { #bindings-assignment }

*Assignment and binding forms* · [в онтологии](concepts.md#bindings-assignment)

- **Одиночное присваивание (layer: language, profile: es2024)**
- **Распаковка при присваивании (layer: language, profile: es2024)** — Деструктуризация массивов и объектов; это также возможно при присваивании существующим переменным.

### Области видимости { #scope }

#### Правило разрешения имён { #scope-resolution }

*Name resolution* · [в онтологии](concepts.md#scope-resolution)

- **Лексическое (layer: language, profile: strict)** — with запрещён; direct eval не добавляет var-связывания в окружение вызывающего.
- **Лексическое (layer: language, profile: sloppy)** — Лексическая основа с исключениями: with добавляет объектное окружение, а direct eval может вводить var в окружение вызывающего. Это не общая динамическая область переменных по стеку вызовов. ([ECMA-262 2024, Strict Mode Code](https://262.ecma-international.org/15.0/#sec-strict-mode-code))

<a id="variants-4"></a>

#### Конструкции областей видимости { #scope-constructs }

*Scoping constructs* · [в онтологии](concepts.md#scope-constructs)

- **Подпрограмма (layer: language, profile: es2024)**
- **Блок (layer: language, profile: es2024)** — let/const имеют область блока; var — область функции либо скрипта.
- **Модуль (layer: language, profile: es2024)**
- **Класс (layer: language, profile: es2024)** — Именование класса и приватные имена; обычное поле не становится лексической переменной метода.

<a id="req-8-2"></a>

#### Связывания верхнего уровня { #scope-globals }

*Top-level bindings* · [в онтологии](concepts.md#scope-globals)

- **Глобальные переменные (layer: language, profile: es2024)** — В Script глобальные var и глобальные лексические let/const представлены разными частями окружения.
- **Имена модуля (layer: language, profile: es2024)** — Имена верхнего уровня модуля не становятся свойствами глобального объекта.

<a id="syntax-shadowing"></a>

#### Сокрытие имён { #scope-shadowing }

*Name shadowing* · [в онтологии](concepts.md#scope-shadowing)

- **Во вложенной области (layer: language, profile: es2024)** — Вложенное let может скрывать внешнее имя; повторное лексическое объявление в одной области запрещено.

### Типизация { #typing }

#### Проверка типов { #typing-checking }

*Type checking* · [в онтологии](concepts.md#typing-checking)

- **Динамическая (layer: language, profile: es2024)**

#### Аннотации типов { #typing-annotations }

*Type annotations* · [в онтологии](concepts.md#typing-annotations)

- **Отсутствуют (layer: language, profile: es2024)** — Аннотации TypeScript не входят в ECMAScript 2024.

<a id="variants-2"></a>
<a id="typing-strength"></a>

#### Преобразования типов { #typing-conversions }

*Type conversions* · [в онтологии](concepts.md#typing-conversions)

- **Неявные (layer: language, profile: es2024)** — Операторы применяют ToPrimitive/ToNumber/ToString/ToBoolean по своим правилам; смешанная арифметика Number и BigInt обычно вызывает TypeError.
- **Явные (layer: language, profile: es2024)** — Number, String, Boolean и BigInt выполняют преобразования значений. ([ECMA-262 2024, Type Conversion](https://262.ecma-international.org/15.0/#sec-type-conversion))

#### Совместимость типов { #typing-compatibility }

*Type compatibility* · [в онтологии](concepts.md#typing-compatibility)

- **По доступным операциям во время выполнения (layer: language, profile: es2024)** — Пользовательские протоколы часто зависят от свойств и вызываемых методов; встроенные операции могут дополнительно проверять внутренние слоты и brand объекта.

#### Представление отсутствия значения { #typing-nullability }

*Absence of a value* · [в онтологии](concepts.md#typing-nullability)

- **Специальное значение (layer: language, profile: es2024)** — null и undefined — разные значения; большинство обращений к их свойствам вызывает TypeError.

### Управление потоком { #control }

<a id="variants-6"></a>

#### Условный выбор { #control-selection }

*Conditional selection* · [в онтологии](concepts.md#control-selection)

- **Условный оператор (layer: language, profile: es2024)**
- **Условное выражение (layer: language, profile: es2024)** — if/else и ?: используют проверку истинности, а не требование значения типа Boolean.

#### Выбор по значению switch/case { #control-switch }

*Switch/case value selection* · [в онтологии](concepts.md#control-switch)

- **да (layer: language, profile: es2024)** — Сравнение case использует строгое равенство; возможен fall-through.

#### Сопоставление с образцом { #control-pattern-matching }

*Pattern matching* · [в онтологии](concepts.md#control-pattern-matching)

- **нет (layer: language, profile: es2024)** — Деструктуризация есть, но отдельной конструкции match в этой редакции нет.

<a id="req-7-2-do-while"></a>

#### Цикл do-while с постусловием { #control-do-while }

*Post-test do-while loop* · [в онтологии](concepts.md#control-do-while)

- **да (layer: language, profile: es2024)**

<a id="req-7-3"></a>

#### Формы итерации { #control-iteration }

*Iteration forms* · [в онтологии](concepts.md#control-iteration)

- **Инициализация / условие / шаг (layer: language, profile: es2024)**
- **По последовательности или итератору (layer: language, profile: es2024)** — for-of обходит iterable; for-in перечисляет перечислимые строковые ключи, включая унаследованные.
- **Функции обхода (layer: standard_library, profile: es2024)** — Методы Array.prototype.map/filter/forEach.

### Подпрограммы и абстракция { #subprograms }

<a id="variants-7"></a>

#### Перегрузка по сигнатуре { #subprograms-overloading }

*Signature overloading* · [в онтологии](concepts.md#subprograms-overloading)

- **нет (layer: language, profile: es2024)** — Нет выбора перегрузки по статическим типам сигнатур; функция может сама анализировать аргументы.

<a id="variants-8"></a>

#### Связывание параметров { #subprograms-parameter-passing }

*Parameter passing* · [в онтологии](concepts.md#subprograms-parameter-passing)

- **По значению (layer: language, profile: es2024, applies_to: значения аргументов)** — Присваивание параметру не изменяет переменную вызывающего.
- **Разделение объекта (layer: language, profile: es2024, applies_to: объектные значения)** — Вызывающий и параметр могут обозначать один объект; изменение его свойств наблюдаемо с обеих сторон. ([ECMA-262 2024, FunctionDeclarationInstantiation](https://262.ecma-international.org/15.0/#sec-functiondeclarationinstantiation))

#### Вложенные именованные подпрограммы { #subprograms-nesting }

*Nested named subprograms* · [в онтологии](concepts.md#subprograms-nesting)

- **да (layer: language, profile: es2024)**

#### Захват окружения { #subprograms-closures }

*Closure capture* · [в онтологии](concepts.md#subprograms-closures)

- **да (layer: language, profile: es2024)** — Функция сохраняет лексическое окружение; стрелочная функция также использует лексический this. ([ECMA-262 2024, OrdinaryFunctionCreate](https://262.ecma-international.org/15.0/#sec-ordinaryfunctioncreate))

#### Анонимные функции { #subprograms-lambda }

*Anonymous functions* · [в онтологии](concepts.md#subprograms-lambda)

- **да (layer: language, profile: es2024)** — Function expressions и arrow functions.

#### Аргументы по умолчанию { #subprograms-default-args }

*Default arguments* · [в онтологии](concepts.md#subprograms-default-args)

- **да (layer: language, profile: es2024)** — Инициализатор параметра вычисляется при вызове, если аргумент отсутствует или равен undefined.

### Полиморфизм и организация { #abstraction }

#### Наследование реализации { #abstraction-inheritance }

*Implementation inheritance* · [в онтологии](concepts.md#abstraction-inheritance)

- **Одиночное (layer: language, profile: es2024)** — Обычный объект имеет одну цепочку [[Prototype]]; class extends использует прототипное наследование.

#### Модульность { #abstraction-modules }

*Modules* · [в онтологии](concepts.md#abstraction-modules)

- **Явная граница экспорта (layer: language, profile: es2024)** — import/export и live bindings; разрешение спецификатора модуля и его загрузка зависят от хоста.

### Вычисление и эффекты { #evaluation }

#### Стратегия вычисления { #evaluation-strategy }

*Evaluation strategy* · [в онтологии](concepts.md#evaluation-strategy)

- **Строгая (layer: language, profile: es2024)** — Обычные аргументы вычисляются слева направо перед вызовом; генераторы откладывают выполнение тела, а не произвольных аргументов.

#### Гарантированное устранение хвостовых вызовов { #evaluation-tail-calls }

*Guaranteed tail-call elimination* · [в онтологии](concepts.md#evaluation-tail-calls)

- **да (layer: language, profile: strict)** — Спецификация требует proper tail calls для определённых хвостовых позиций; это не утверждение о поддержке всеми движками. ([ECMA-262 2024, Tail Position Calls](https://262.ecma-international.org/15.0/#sec-tail-position-calls))
- **нет (layer: language, profile: sloppy)** — Нестрогий код не получает этой гарантии спецификации.

### Память и владение { #memory }

#### Передача и разделение владения { #memory-transfer }

*Ownership transfer and sharing* · [в онтологии](concepts.md#memory-transfer)

- **Разделяемая ссылка на объект (layer: language, profile: es2024, applies_to: объекты)** — Присваивание не копирует граф объекта.

### Каналы ошибок { #errors }

#### Представление и передача ошибок { #errors-model }

*Error representation and propagation* · [в онтологии](concepts.md#errors-model)

- **Исключения (layer: language, profile: es2024)** — throw принимает любое значение; try/catch перехватывает исключительное завершение.

### Ресурсы и взаимодействие { #resources }

<a id="errors-finally"></a>

#### Освобождение ресурсов { #resources-cleanup }

*Resource cleanup* · [в онтологии](concepts.md#resources-cleanup)

- **Блок finally / unwind-protect (layer: language, profile: es2024)** — try/finally выполняет очистку при обычном и исключительном выходе; возврат или throw из finally может заменить исходный результат.

#### Конкурентное выполнение { #resources-concurrency }

*Concurrency* · [в онтологии](concepts.md#resources-concurrency)

- **Асинхронные корутины (layer: language, profile: es2024)** — async/await и Promise координируют асинхронные вычисления; источники событий, I/O и запуск workers задаёт хост. ([ECMA-262 2024, Async Function Definitions](https://262.ecma-international.org/15.0/#sec-async-function-definitions))

### Синтаксис и метапрограммирование { #syntax }

<a id="variants-5"></a>

#### Границы синтаксических групп { #syntax-blocks }

*Syntactic grouping boundaries* · [в онтологии](concepts.md#syntax-blocks)

- **Явные разделители (layer: language, profile: es2024)**

#### Границы операторов и определений { #syntax-statement-terminator }

*Statement and definition boundaries* · [в онтологии](concepts.md#syntax-statement-terminator)

- **Необязательная точка с запятой (layer: language, profile: es2024)** — Automatic Semicolon Insertion действует по формальным правилам; перенос строки не всегда эквивалентен точке с запятой.

### Парадигмы { #paradigm }

#### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms* · [в онтологии](concepts.md#paradigm-supported)

- **Императивная (layer: language, profile: es2024)**
- **Объектно-ориентированная (layer: language, profile: es2024)**
- **Функциональная (layer: language, profile: es2024)**
