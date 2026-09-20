---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные index.md и concepts.md сохраняются при пересборке. -->

# Онтология концепций

Общий словарь, по которому описаны все языки каталога. Значение в ячейке матрицы — из закрытого перечисления; в скобках — версия, с которой оно появилось. Подробности (область применимости, примечания, источники, код) — на карточке языка по ссылке в ячейке. «—» — концепция неприменима к языку; пустая ячейка — данных нет.

## Покрытие { #coverage }

Доля значений перечислений, для которых в каталоге есть хотя бы один язык. Непокрытые значения ждут языков, указанных в скобках.

| Категория | Покрыто | Ожидают языков |
|---|---|---|
| Свойства проектируемого языка | 21/24 (88%) | variants.8.by_result (ожидается: Ada out, C# out); variants.8.by_ref (ожидается: C++ &, C# ref, Pascal var); variants.9.program_start (ожидается: Pascal, C89-стиль) |
| Обязательные требования к языку | 7/7 (100%) | — |
| Типизация | 6/8 (75%) | typing.strength.weak (ожидается: JavaScript, C); typing.nullability.nullable_types (ожидается: Kotlin, C# 8, Swift, TypeScript strict) |
| Управление памятью | 3/4 (75%) | memory.management.manual (ожидается: C, C++) |
| Парадигмы программирования | 4/7 (57%) | paradigm.supported.declarative (ожидается: SQL, Prolog, HTML); paradigm.supported.logic (ожидается: Prolog); paradigm.supported.event_driven (ожидается: JavaScript, C#) |
| Обработка исключительных ситуаций | 2/3 (67%) | errors.model.unstructured (ожидается: C signal, Go panic/recover) |
| Синтаксическая структура | 5/6 (83%) | syntax.statement_terminator.optional_semicolon (ожидается: Kotlin, Go, JavaScript, Swift) |

## Свойства проектируемого языка { #variants }

Девять свойств, по которым студенту выдаётся вариант (docs/labs/variants.md, раздел 1). Здесь — как эти свойства решены в реальных языках.

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Объявление переменных](#variants-1) | [Явное; Неявное (Java SE 10) *](java.md#variants-1) | [Неявное *](python.md#variants-1) | [Явное *](rust.md#variants-1) |
| [Преобразование типов](#variants-2) | [Явное; Неявное *](java.md#variants-2) | [Явное; Неявное *](python.md#variants-2) | [Явное *](rust.md#variants-2) |
| [Оператор присваивания](#variants-3) | [Одиночный *](java.md#variants-3) | [Одиночный; Множественный *](python.md#variants-3) | [Одиночный; Множественный (Rust 1.59) *](rust.md#variants-3) |
| [Структуры, ограничивающие область видимости](#variants-4) | [Подпрограммы и блочные операторы *](java.md#variants-4) | [Подпрограммы *](python.md#variants-4) | [Подпрограммы и блочные операторы *](rust.md#variants-4) |
| [Маркер блочного оператора](#variants-5) | [Явный *](java.md#variants-5) | [Неявный *](python.md#variants-5) | [Явный *](rust.md#variants-5) |
| [Условные операторы](#variants-6) | [Двухвариантный и многовариантный switch-case *](java.md#variants-6) | [Только двухвариантный if-then-else (до Python 3.10); Двухвариантный и многовариантный switch-case (Python 3.10) *](python.md#variants-6) | [Двухвариантный и многовариантный switch-case *](rust.md#variants-6) |
| [Перегрузка подпрограмм](#variants-7) | [Присутствует *](java.md#variants-7) | [Отсутствует *](python.md#variants-7) | [Отсутствует *](rust.md#variants-7) |
| [Передача параметров в подпрограмму](#variants-8) | [По значению; По ссылке на объект *](java.md#variants-8) | [По ссылке на объект *](python.md#variants-8) | [По значению; Перемещение; Заимствование; Изменяемое заимствование *](rust.md#variants-8) |
| [Допустимое место объявления подпрограмм](#variants-9) | [Только как члены класса *](java.md#variants-9) | [В любом месте *](python.md#variants-9) | [В любом месте *](rust.md#variants-9) |

### Объявление переменных { #variants-1 }

*Variable declaration*

- `explicit` — **Явное** (*explicit declaration*): переменная вводится отдельной конструкцией объявления (тип или ключевое слово)
- `implicit` — **Неявное** (*implicit declaration*): переменная возникает при первом присваивании

### Преобразование типов { #variants-2 }

*Type conversion*

- `explicit` — **Явное** (*explicit conversion*): например, `a = (int) b`
- `implicit` — **Неявное** (*implicit conversion (coercion)*)

### Оператор присваивания { #variants-3 }

*Assignment*

- `single` — **Одиночный** (*single assignment*): например, `a = b`
- `multiple` — **Множественный** (*multiple assignment*): например, `a, b = c, d`

### Структуры, ограничивающие область видимости { #variants-4 }

*Scoping constructs*

- `subprograms` — **Подпрограммы** (*subprograms only*)
- `subprograms_and_blocks` — **Подпрограммы и блочные операторы** (*subprograms and blocks*)

### Маркер блочного оператора { #variants-5 }

*Block delimiter*

- `explicit` — **Явный** (*explicit delimiters*): например, `{ }` или `begin end`
- `implicit` — **Неявный** (*significant indentation*): как в Python

### Условные операторы { #variants-6 }

*Conditional statements*

- `if_only` — **Только двухвариантный if-then-else** (*if-then-else only*) — *в каталоге пока нет; ожидается: Lua, Bash, Pascal без case*
- `if_and_switch` — **Двухвариантный и многовариантный switch-case** (*if and switch/match*)

### Перегрузка подпрограмм { #variants-7 }

*Subprogram overloading*

- `absent` — **Отсутствует** (*no overloading*)
- `present` — **Присутствует** (*overloading*)

### Передача параметров в подпрограмму { #variants-8 }

*Parameter passing*

Перечисление расширено относительно variants.md: три исходных варианта не описывают ни один из языков каталога.

- `by_value` — **По значению** (*by value*)
- `by_result` — **По результату** (*by result (out)*) — *в каталоге пока нет; ожидается: Ada out, C# out*
- `by_ref` — **По ссылке** (*by reference*) — *в каталоге пока нет; ожидается: C++ &, C# ref, Pascal var*
- `by_sharing` — **По ссылке на объект** (*call by sharing*): копируется ссылка на объект; сам объект не копируется
- `move` — **Перемещение** (*move semantics*)
- `borrow` — **Заимствование** (*shared borrow*)
- `borrow_mut` — **Изменяемое заимствование** (*mutable borrow*)

### Допустимое место объявления подпрограмм { #variants-9 }

*Subprogram declaration placement*

- `program_start` — **В начале программы** (*at program start*) — *в каталоге пока нет; ожидается: Pascal, C89-стиль*
- `anywhere` — **В любом месте** (*anywhere*)
- `class_members_only` — **Только как члены класса** (*class members only*): свободных и вложенных подпрограмм нет; обход — лямбды и локальные классы

## Обязательные требования к языку { #requirements }

Из docs/_partials/language-requirements.md взяты только пункты, по которым реальные языки различаются. Пункты, истинные для любого языка (есть типы, операции, выражения, блок, if, for), не заводятся.

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Встроенный ввод-вывод](#req-4) | [Функции стандартной библиотеки *](java.md#req-4) | [Встроенные функции *](python.md#req-4) | [Макросы; Функции стандартной библиотеки *](rust.md#req-4) |
| [Цикл с постусловием until](#req-7-2-until) | [нет *](java.md#req-7-2-until) | [нет *](python.md#req-7-2-until) | [нет *](rust.md#req-7-2-until) |
| [Цикл do-while](#req-7-2-do-while) | [да](java.md#req-7-2-do-while) | [нет *](python.md#req-7-2-do-while) | [нет *](rust.md#req-7-2-do-while) |
| [Оператор цикла с итерациями for](#req-7-3) | [Счётный (в стиле C); По коллекции (foreach) (Java SE 5) *](java.md#req-7-3) | [По коллекции (foreach) *](python.md#req-7-3) | [По коллекции (foreach) *](rust.md#req-7-3) |
| [Глобальная область видимости для переменных](#req-8-2) | [Глобальных переменных нет *](java.md#req-8-2) | [Есть глобальные переменные *](python.md#req-8-2) | [Есть глобальные переменные *](rust.md#req-8-2) |

### Встроенный ввод-вывод { #req-4 }

*Built-in I/O*

п. 4.1: read() и write() — чем они являются в языке

- `builtin` — **Встроенные функции** (*built-in functions*)
- `stdlib` — **Функции стандартной библиотеки** (*standard library*)
- `macro` — **Макросы** (*macros*)

### Цикл с постусловием until { #req-7-2-until }

*until loop*

п. 7.2 требует while и until; until нет ни в одном языке каталога — показывается эквивалент

- да / нет

### Цикл do-while { #req-7-2-do-while }

*do-while loop*

- да / нет

### Оператор цикла с итерациями for { #req-7-3 }

*for loop form*

- `c_style` — **Счётный (в стиле C)** (*C-style counted loop*)
- `foreach` — **По коллекции (foreach)** (*foreach*)

### Глобальная область видимости для переменных { #req-8-2 }

*Global variables*

- `globals` — **Есть глобальные переменные** (*globals*)
- `no_globals` — **Глобальных переменных нет** (*no globals*): эквивалент — статические поля класса

## Типизация { #typing }

Термины лекций 02 (классификация) и 20 (типы, проверка типов).

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Проверка типов](#typing-checking) | [Статическая](java.md#typing-checking) | [Динамическая; Постепенная (Python 3.5) *](python.md#typing-checking) | [Статическая](rust.md#typing-checking) |
| [Сильная и слабая типизация](#typing-strength) | [Сильная *](java.md#typing-strength) | [Сильная *](python.md#typing-strength) | [Сильная *](rust.md#typing-strength) |
| [Вывод типов](#typing-inference) | [да (Java SE 10) *](java.md#typing-inference) | [нет *](python.md#typing-inference) | [да *](rust.md#typing-inference) |
| [Отсутствие значения (null)](#typing-nullability) | [null допустим в любом ссылочном типе *](java.md#typing-nullability) | [null допустим в любом ссылочном типе *](python.md#typing-nullability) | [Отдельный тип-обёртка (Option/Optional) *](rust.md#typing-nullability) |

### Проверка типов { #typing-checking }

*Type checking* · также: статическая типизация, динамическая типизация

- `static` — **Статическая** (*static*): ошибки типов обнаруживаются до запуска программы
- `dynamic` — **Динамическая** (*dynamic*): ошибка проявится при выполнении проблемной ветки
- `gradual` — **Постепенная** (*gradual*): опциональные статические аннотации поверх динамической проверки

### Сильная и слабая типизация { #typing-strength }

*Type strength* · также: строгая типизация

- `strong` — **Сильная** (*strong*): большинство опасных приведений запрещены
- `weak` — **Слабая** (*weak*): язык неявно приводит типы — *в каталоге пока нет; ожидается: JavaScript, C*

### Вывод типов { #typing-inference }

*Type inference*

- да / нет

### Отсутствие значения (null) { #typing-nullability }

*Nullability*

- `nullable_everywhere` — **null допустим в любом ссылочном типе** (*nullable references*)
- `optional_type` — **Отдельный тип-обёртка (Option/Optional)** (*option type*)
- `nullable_types` — **Nullable-типы в системе типов (T?)** (*nullable types*) — *в каталоге пока нет; ожидается: Kotlin, C# 8, Swift, TypeScript strict*

## Управление памятью { #memory }

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Освобождение памяти](#memory-management) | [Сборка мусора *](java.md#memory-management) | [Подсчёт ссылок; Сборка мусора *](python.md#memory-management) | [Владение и время жизни; Подсчёт ссылок *](rust.md#memory-management) |

### Освобождение памяти { #memory-management }

*Memory reclamation*

- `gc` — **Сборка мусора** (*garbage collection*)
- `refcount` — **Подсчёт ссылок** (*reference counting*)
- `ownership` — **Владение и время жизни** (*ownership and lifetimes*)
- `manual` — **Ручное** (*manual*) — *в каталоге пока нет; ожидается: C, C++*

## Парадигмы программирования { #paradigm }

Список лекции 02.

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Поддерживаемые парадигмы](#paradigm-supported) | [Императивная; Процедурная; Объектно-ориентированная; Функциональная (Java SE 8) *](java.md#paradigm-supported) | [Императивная; Процедурная; Объектно-ориентированная; Функциональная *](python.md#paradigm-supported) | [Императивная; Процедурная; Функциональная; Объектно-ориентированная *](rust.md#paradigm-supported) |

### Поддерживаемые парадигмы { #paradigm-supported }

*Supported paradigms*

- `imperative` — **Императивная** (*imperative*)
- `procedural` — **Процедурная** (*procedural*)
- `object_oriented` — **Объектно-ориентированная** (*object-oriented*)
- `functional` — **Функциональная** (*functional*)
- `declarative` — **Декларативная** (*declarative*) — *в каталоге пока нет; ожидается: SQL, Prolog, HTML*
- `logic` — **Логическая** (*logic*) — *в каталоге пока нет; ожидается: Prolog*
- `event_driven` — **Событийно-ориентированная** (*event-driven*) — *в каталоге пока нет; ожидается: JavaScript, C#*

## Обработка исключительных ситуаций { #errors }

Лекция 20, слайд «Обработка исключительных ситуаций».

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Модель обработки ошибок](#errors-model) | [Структурная (try-throw-catch) *](java.md#errors-model) | [Структурная (try-throw-catch) *](python.md#errors-model) | [Значение-результат (Result / коды ошибок) *](rust.md#errors-model) |
| [Блоки с гарантированным завершением](#errors-finally) | [да *](java.md#errors-finally) | [да *](python.md#errors-finally) | [нет *](rust.md#errors-finally) |
| [Проверяемые исключения в сигнатуре](#errors-checked) | [да *](java.md#errors-checked) | [нет](python.md#errors-checked) | [да *](rust.md#errors-checked) |

### Модель обработки ошибок { #errors-model }

*Error handling model*

- `unstructured` — **Неструктурная (регистрируемый обработчик)** (*unstructured handlers*) — *в каталоге пока нет; ожидается: C signal, Go panic/recover*
- `exceptions` — **Структурная (try-throw-catch)** (*structured exceptions*)
- `result_type` — **Значение-результат (Result / коды ошибок)** (*result values*)

### Блоки с гарантированным завершением { #errors-finally }

*Guaranteed cleanup blocks*

- да / нет

### Проверяемые исключения в сигнатуре { #errors-checked }

*Checked exceptions*

- да / нет

## Подпрограммы и абстракция { #subprograms }

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Лямбда-функции](#subprograms-lambda) | [да (Java SE 8) *](java.md#subprograms-lambda) | [да *](python.md#subprograms-lambda) | [да *](rust.md#subprograms-lambda) |
| [Обобщённые типы и подпрограммы](#subprograms-generics) | [да (Java SE 5) *](java.md#subprograms-generics) | [да (Python 3.5) *](python.md#subprograms-generics) | [да *](rust.md#subprograms-generics) |
| [Параметры по умолчанию](#subprograms-default-args) | [нет *](java.md#subprograms-default-args) | [да *](python.md#subprograms-default-args) | [нет *](rust.md#subprograms-default-args) |
| [Именованные аргументы](#subprograms-named-args) | [нет *](java.md#subprograms-named-args) | [да](python.md#subprograms-named-args) | [нет *](rust.md#subprograms-named-args) |

### Лямбда-функции { #subprograms-lambda }

*Lambda functions* · также: анонимные функции, замыкания

- да / нет

### Обобщённые типы и подпрограммы { #subprograms-generics }

*Generics* · также: шаблоны, дженерики

- да / нет

### Параметры по умолчанию { #subprograms-default-args }

*Default arguments*

- да / нет

### Именованные аргументы { #subprograms-named-args }

*Named arguments*

- да / нет

## Синтаксическая структура { #syntax }

Лекция 20, слайд «Синтаксическая структура».

| Концепция | [Java](java.md) | [Python](python.md) | [Rust](rust.md) |
|---|---|---|---|
| [Разделитель операторов](#syntax-statement-terminator) | [Точка с запятой обязательна](java.md#syntax-statement-terminator) | [Перевод строки *](python.md#syntax-statement-terminator) | [Точка с запятой обязательна *](rust.md#syntax-statement-terminator) |
| [Чувствительность к регистру](#syntax-case-sensitive) | [да](java.md#syntax-case-sensitive) | [да](python.md#syntax-case-sensitive) | [да](rust.md#syntax-case-sensitive) |
| [Совмещение имён (shadowing)](#syntax-shadowing) | [Запрещено внутри одной подпрограммы; Разрешено во вложенной области *](java.md#syntax-shadowing) | [Разрешено во вложенной области; Разрешено даже в той же области *](python.md#syntax-shadowing) | [Разрешено во вложенной области; Разрешено даже в той же области *](rust.md#syntax-shadowing) |

### Разделитель операторов { #syntax-statement-terminator }

*Statement terminator*

- `semicolon` — **Точка с запятой обязательна** (*mandatory semicolon*)
- `newline` — **Перевод строки** (*newline*)
- `optional_semicolon` — **Точка с запятой необязательна** (*optional semicolon*) — *в каталоге пока нет; ожидается: Kotlin, Go, JavaScript, Swift*

### Чувствительность к регистру { #syntax-case-sensitive }

*Case sensitivity*

- да / нет

### Совмещение имён (shadowing) { #syntax-shadowing }

*Shadowing* · также: совпадение имён, ограниченное совмещение имен

- `allowed` — **Разрешено во вложенной области** (*allowed in nested scope*)
- `forbidden_in_block` — **Запрещено внутри одной подпрограммы** (*forbidden within a subprogram*)
- `allowed_same_scope` — **Разрешено даже в той же области** (*allowed in the same scope*)

## Оценка по критериям лекции 20 { #assessment }

Критерии — не свойства, а оценки; каждая ссылается на концепции, из которых выводится.

| Критерий | [Java](java.md#assessment) | [Python](python.md#assessment) | [Rust](rust.md#assessment) |
|---|---|---|---|
| Читабельность | Явные типы в объявлениях и сигнатурах делают код самодокументируемым, но многословным: обвязка классов и обязательные скобки увеличивают объём по сравнению с Python и Kotlin. | Отступы вместо скобок и минимум служебных слов делают код коротким и единообразным; отсутствие типов в сигнатурах затрудняет чтение больших программ, аннотации частично это компенсируют. | Синтаксис явный и единообразный (скобки, `let`, типы в сигнатурах), но аннотации времён жизни и обобщений с ограничениями трейтов делают сигнатуры длинными; для новичка — самый сложный из языков каталога. |
| Лёгкость создания | Перегрузка, `var`, лямбды и Stream API сократили код по сравнению с ранними версиями; отсутствие свободных функций, параметров по умолчанию и множественного присваивания остаётся. | Неявное объявление, множественное присваивание, встроенные коллекции и ввод-вывод без импорта — программа пишется быстро; ошибки типов откладываются до запуска. | Вывод типов внутри функций и выражения-блоки сокращают код, но проверка заимствований заставляет заранее продумывать владение данными; высокая «входная цена». |
| Надёжность | Статическая типизация и проверяемые исключения ловят ошибки на этапе компиляции; `null` допустим в любой ссылке и остаётся главным источником ошибок времени выполнения. | Сильная типизация ловит смешение строк и чисел, но только во время выполнения; надёжность держится на тестах и внешних проверках аннотаций. Исключения структурные, с `finally` и `with`. | Статическая сильная типизация, отсутствие null, обязательная обработка `Result` и проверка владения исключают целые классы ошибок на этапе компиляции. |
| Стоимость | Зрелая экосистема JVM и инструменты; цена — многословность, время старта JVM и потребление памяти. | Низкий порог входа, огромная экосистема; цена — скорость выполнения и расходы на тесты вместо компилятора. | Дольше учить и дольше компилировать; окупается там, где критичны производительность и безопасность памяти без сборщика мусора. |
