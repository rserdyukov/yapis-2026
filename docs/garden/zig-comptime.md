---
publish: true
title: "Zig: comptime вместо макросов"
description: "В Zig код времени компиляции пишется на том же языке, что и код времени выполнения: типы — значения, обобщения — функции, возвращающие типы, а препроцессор и макросы не нужны."
languages: [zig]
concepts: [syntax.metaprogramming, syntax.macro_hygiene, subprograms.generics, subprograms.generic_mechanism, typing.checking]
---

# Zig: comptime вместо макросов

*Если компилятор всё равно умеет выполнять код, пусть программист пишет код времени компиляции на том же языке, а не на отдельном языке макросов.*

## Проблема

Почти каждому системному языку нужно что-то вычислять до запуска программы:
размеры массивов и таблицы констант, специализированный код для разных типов,
проверку формата строки `printf`, условную компиляцию под платформу. Разные
языки решали эту задачу отдельным механизмом, стоящим *рядом* с языком.

**Препроцессор C** работает до компилятора и заменяет последовательности
токенов. Он ничего не знает о приоритете операций, типах и областях
видимости. Поэтому макросы надо окружать скобками, аргумент с побочным
эффектом может выполниться дважды, а имя внутри макроса может случайно совпасть
с именем в месте вызова ([негигиеничность](../languages/glossary.md#syntax-macro-hygiene)).

**Шаблоны C++** — второй, уже типизированный язык внутри языка: свой синтаксис
`template <...>`, свои правила вывода и специализации, а для вычислений —
`constexpr`, `consteval`, `if constexpr`. Всё это мощно, но программисту
приходится держать в голове несколько подъязыков
([Stroustrup, HOPL II](../languages/sources.md#hopl-cpp)).

**Макросы Lisp и Rust** работают со структурой программы, а не с текстом:
макрос получает дерево (формы или токены) и возвращает дерево. Это решает
проблемы C, но макрос — всё ещё отдельная сущность со своими правилами
раскрытия, которую вызывают иначе, чем функцию.

Язык Zig, созданный [Эндрю Келли](../languages/people.md#andrew-kelley),
задаёт вопрос: зачем отдельный язык, если компилятор может просто
**выполнить** обычный код во время компиляции?

## Идея

В Zig у каждого выражения есть свойство: известно ли его значение при
компиляции (comptime-known) или только во время выполнения. Ключевое слово
`comptime` требует, чтобы параметр, переменная или блок были вычислены
компилятором; если это невозможно, получается ошибка компиляции. Сам код при
этом обычный: те же `if`, `while`, `for`, `switch`, те же функции. Компилятор
во время семантического анализа **интерпретирует** их
([Language Reference: comptime](https://ziglang.org/documentation/0.16.0/#comptime)).

Второй шаг: **типы — значения первого класса** времени компиляции. Тип можно
сохранить в константу, передать как параметр `comptime T: type` и вернуть из
функции. Отсюда следуют три вещи:

- обобщённая функция — функция с параметром-типом;
- обобщённая структура данных — функция, которая *возвращает* тип
  (`fn List(comptime T: type) type`);
- рефлексия — встроенная функция `@typeInfo(T)`, которая превращает тип в
  обычную структуру данных, по которой можно пройти циклом.

На обзорной странице языка это сформулировано как свойство «маленького
простого языка»: в Zig нет скрытого потока управления, скрытых выделений
памяти, препроцессора и макросов ([ziglang.org: Overview](https://ziglang.org/learn/overview/)).
А в разделе о `print` Language Reference подчёркивает, что форматированный
вывод написан в стандартной библиотеке на самом Zig, без отдельного языка
макросов или препроцессора ([Case Study: print in Zig](https://ziglang.org/documentation/0.16.0/#Case-Study-print-in-Zig)).

## Как это работает

Все примеры на Zig в этом разделе **не запускались**: компилятора Zig в
окружении автора нет. Код написан консервативно по
[Language Reference 0.16.0](https://ziglang.org/documentation/0.16.0/) (эту
версию описывает [карточка языка](../languages/zig.md)); ожидаемый вывод
выведен из указанных разделов. `std.debug.print` пишет в stderr. Запуск —
`zig run имя.zig` (или `bash src/zig-comptime/run.sh`).

### Обобщения как функции

```zig title="generic.zig"
--8<-- "src/zig-comptime/generic.zig:max"

--8<-- "src/zig-comptime/generic.zig:stack"

--8<-- "src/zig-comptime/generic.zig:main"
```

```text title="Вывод (ожидаемый)"
5 2.5
pop: 20, len: 1
```

**Не запускалось:** вывод по [Compile-Time Parameters](https://ziglang.org/documentation/0.16.0/#Compile-Time-Parameters)
(пример `max(comptime T: type, a: T, b: T) T` взят оттуда),
[Generic Data Structures](https://ziglang.org/documentation/0.16.0/#Generic-Data-Structures),
[@This](https://ziglang.org/documentation/0.16.0/#This).

Здесь нет синтаксиса шаблонов. `Stack` — обычная функция; `Stack(i32, 4)` —
обычный вызов, который выполняется при компиляции и возвращает новую
анонимную структуру. Для сообщений об ошибках Zig выводит её имя из имени
функции и аргументов (в Language Reference — пример `List(i32)`). Параметр `capacity` — не тип, а число, и он
тоже comptime: в C++ для этого понадобился бы отдельный вид шаблонного
параметра `std::size_t N`.

Language Reference называет этот механизм *compile-time duck typing*:
ограничения на `T` нигде не записаны, тело проверяется при каждом
инстанцировании. Вызов `max(bool, true, false)` даст ошибку
`operator > not allowed for type 'bool'` внутри тела `max`. Каждый новый набор
comptime-аргументов порождает отдельную специализированную функцию — это
[мономорфизация](../languages/glossary.md#subprograms-generic-mechanism).

### Один язык для обеих фаз

```zig title="comptime_eval.zig"
--8<-- "src/zig-comptime/comptime_eval.zig:code"
```

```text title="Вывод (ожидаемый)"
fib7 = 13, array.len = 8, table[4] = 16
0 1 1 2 3 5 
```

**Не запускалось:** вывод по [Compile-Time Expressions](https://ziglang.org/documentation/0.16.0/#Compile-Time-Expressions)
(выражения уровня контейнера неявно comptime, пример с `fibonacci` и
`firstNPrimes`), [Container Level Variables](https://ziglang.org/documentation/0.16.0/#Container-Level-Variables).

Функция `fibonacci` написана один раз и вызывается в трёх контекстах:
инициализация глобальной константы, длина массива (часть типа, значит
обязана быть известна компилятору) и обычный цикл во время выполнения.
Language Reference отдельно отмечает, что программист может написать функцию,
которую вызывают и при компиляции, и при выполнении, без каких-либо изменений в
ней. В C++ для той же функции нужна пометка `constexpr`, в Rust — `const fn`
с более узким набором разрешённых операций.

Если вычисление при компиляции ошибочно — например, в `fibonacci` забыт
базовый случай и `u32` уходит в минус, — компилятор выдаёт ошибку
`overflow of integer type 'u32' with value '-1'` с «трассой стека» вызовов
времени компиляции (`note: called at comptime here`). Бесконечную рекурсию
ограничивает квота ветвлений (по умолчанию 1000, меняется
[`@setEvalBranchQuota`](https://ziglang.org/documentation/0.16.0/#setEvalBranchQuota)).
Language Reference 0.16.0 честно предупреждает, что из-за дефекта компилятора
в этом случае вместо ошибки может произойти переполнение стека.

### Рефлексия и развёрнутый цикл

```zig title="reflection.zig"
--8<-- "src/zig-comptime/reflection.zig:code"
```

```text title="Вывод (ожидаемый)"
magic: u32
name: []const u8
u8: целое, f64: с плавающей точкой, bool: логическое
u8 bool f32 
```

**Не запускалось:** вывод по [@typeInfo](https://ziglang.org/documentation/0.16.0/#typeInfo),
[@typeName](https://ziglang.org/documentation/0.16.0/#typeName),
[inline for](https://ziglang.org/documentation/0.16.0/#inline-for),
[Tuples](https://ziglang.org/documentation/0.16.0/#Tuples); пример
`printInfoAboutStruct` с тем же выводом полей — на
[странице Overview](https://ziglang.org/learn/overview/#compile-time-reflection-and-compile-time-code-execution).

`@typeInfo(T)` возвращает значение типа `std.builtin.Type` — размеченное
объединение с вариантами `.int`, `.float`, `.@"struct"` и т. д. Список полей
структуры — обычный массив, но у элементов разные типы полей, поэтому обычный
`for` не подойдёт: переменная цикла должна иметь один тип во время
выполнения. `inline for` разворачивает цикл при компиляции, и на каждой копии
тела `field` — отдельное comptime-значение. Так же обходится кортеж разнородных
значений.

`switch` по comptime-известному значению тоже вычисляется при компиляции, и
компилятор **гарантирует**, что невыбранные ветви не анализируются. Поэтому
`@compileError` в ветви `else` не срабатывает для `u8`, `f64` и `bool`.

### Ошибки компиляции как библиотечный код

```zig title="compile_error.zig"
--8<-- "src/zig-comptime/compile_error.zig:code"
```

```text title="Ожидаемая ошибка компиляции (ключевая строка)"
compile_error.zig:8:17: error: нет описания для compile_error.Point
```

**Не запускалось:** поведение по [@compileError](https://ziglang.org/documentation/0.16.0/#compileError)
(«when semantically analyzed, causes a compile error with the message msg»)
и [@typeName](https://ziglang.org/documentation/0.16.0/#typeName) (имя типа
полностью квалифицировано именем файла-контейнера). Номер столбца приблизителен.

`@compileError` — это способ, которым библиотека сообщает пользователю о
неправильном использовании на этапе компиляции. Так устроен `std.debug.print`:
лишний аргумент в строке формата даёт ошибку
`unused argument in '...'`, выданную `@compileError` из кода стандартной
библиотеки, а не встроенной проверкой в компиляторе
([Case Study: print in Zig](https://ziglang.org/documentation/0.16.0/#Case-Study-print-in-Zig)).
В C язык формат `printf` не проверяет; это делают компиляторы (GCC, Clang)
как особый случай — встроенной диагностикой для функций с атрибутом `format`.

Вторая половина примера — оборотная сторона той же гарантии: функция
`neverCalled` содержит явную ошибку типов, но её никто не вызывает, и
компилятор её не проверяет. К этому мы вернёмся в разделе «Цена».

## Цена

**Ленивый анализ: непроверенный код.** Объявления верхнего уровня
анализируются лениво: анализируется только то, на что есть ссылка
([File and Declaration Discovery](https://ziglang.org/documentation/0.16.0/#File-and-Declaration-Discovery);
то же упомянуто в разделе
[C Translation — Translation failures](https://ziglang.org/documentation/0.16.0/#Translation-failures)
и про переменные уровня контейнера), а ветви comptime-`if`/`switch` не
анализируются, если не выбраны. Это необходимо: иначе `@compileError` в
`else` сработал бы всегда, а код под `if (builtin.os.tag == .windows)`
не компилировался бы на Linux. Но следствие неприятное: функция, которую не
вызвали тесты, может содержать ошибки типов, и сборка пройдёт. Библиотеке нужны
тесты, которые инстанцируют каждую обобщённую функцию с разными типами.

**Утиная типизация при компиляции — поздние и длинные ошибки.** Требования к
`T` нигде не записаны в сигнатуре, поэтому ошибка обнаруживается в теле
обобщённой функции, иногда глубоко в стандартной библиотеке, с цепочкой
`referenced by:` / `called at comptime here`. Это та же проблема, из-за которой
в C++20 появились концепты: без явного контракта пользователь читает не свой
код. Для обобщённого кода и
[статической проверки](../languages/glossary.md#typing-checking) это значит:
проверка по-прежнему выполняется до запуска, но *при инстанцировании*, а не при
определении.

**Сложность двухфазной семантики.** Программист должен различать, что
известно при компиляции, а что нет. Один и тот же `for` — цикл во время
выполнения, а `inline for` — разворачивание при компиляции. Ошибка
`unable to resolve comptime value` появляется, когда значение времени
выполнения попадает туда, где нужно comptime. Язык стал меньше, но появилось
новое измерение, которое проходит через все конструкции.

**Время компиляции.** Интерпретатор внутри компилятора выполняет
произвольный код, и тяжёлые вычисления замедляют сборку. Квота ветвлений
защищает от зацикливания, но не от медленных вычислений. Каждая мономорфная
копия увеличивает объём генерируемого кода.

**Язык до 1.0.** Встроенные функции для построения типов и API стандартной
библиотеки меняются между выпусками; в примерах этой статьи сознательно
использован минимум API. Код, написанный для одного выпуска, может не
собираться следующим.

**Ограниченность.** comptime не может делать всё, что умеют макросы: нельзя
ввести новый синтаксис, нельзя вызывать внешние функции при компиляции (ошибка
`comptime call of extern function`), нет ввода-вывода. Это сознательное
ограничение: код по-прежнему выглядит как Zig, а сборка воспроизводима.

## Сравнение

### C: текстовые макросы

```c title="macros.c"
--8<-- "src/zig-comptime/macros.c:defs"
```

```c title="macros.c (main)"
--8<-- "src/zig-comptime/macros.c:use"
```

```text title="Вывод"
SQUARE(1 + 2) = 5
MAX(i++, j) = 4, i = 5
PRINT_TWICE(i * 10):
  0
  10
```

**Проверено:** Apple clang 17.0.0 (`cc -std=c11`), macOS.

Три классические ошибки препроцессора в одной программе. `SQUARE(1 + 2)`
раскрывается в `1 + 2 * 1 + 2`, то есть 5. `MAX(i++, j)` вычисляет `i++`
дважды: один раз в сравнении, второй раз в выбранной ветви, поэтому результат
4, а `i` стало 5. В `PRINT_TWICE(i * 10)` переменная `i` из аргумента после
подстановки оказывается в области видимости `int i` внутри макроса и
печатает счётчик цикла, а не 70. Препроцессор работает с токенами
([cppreference: Replacing text macros](https://en.cppreference.com/w/c/preprocessor/replace)),
поэтому гигиены у него нет. В Zig ни одна из этих ошибок невозможна:
`max(i32, a, b)` — это вызов функции, аргументы вычисляются один раз и
передаются как значения.

### C++: шаблоны и `constexpr`

```cpp title="templates.cpp"
--8<-- "src/zig-comptime/templates.cpp:code"
```

```text title="Вывод"
8 13
5 2.5
20
```

**Проверено:** Apple clang 17.0.0 (`clang++ -std=c++17`), macOS.

По возможностям это близко к Zig: `constexpr`-функция работает в обеих фазах,
шаблоны мономорфизуются. Разница — в числе механизмов: `constexpr`, `template`,
нетиповые параметры шаблона, `static_assert`, `if constexpr`, а для
рефлексии в C++17 — специализации и трейты типов. Ограничений на `T` тоже нет,
пока не используются концепты C++20, и ошибка всплывает в теле шаблона:

```cpp title="template_error.cpp"
--8<-- "src/zig-comptime/template_error.cpp"
```

```text title="Вывод компилятора"
template_error.cpp:3:14: error: invalid operands to binary expression ('Point' and 'Point')
    3 |     return a > b ? a : b;
      |            ~ ^ ~
template_error.cpp:12:5: note: in instantiation of function template specialization 'max_of<Point>' requested here
```

**Проверено:** Apple clang 17.0.0 (`clang++ -std=c++17 -fsyntax-only`), macOS.

Сообщение устроено так же, как у Zig для `max(bool, ...)`: ошибка в теле плюс
цепочка «где инстанцировано». Утиная типизация при компиляции даёт похожие
диагностики в обоих языках.

### Rust: синтаксические макросы и `const fn`

```rust title="macros.rs"
--8<-- "src/zig-comptime/macros.rs:code"
```

```text title="Вывод"
square!(1 + 2) = 9
max!(i++, 2) = 3, i = 4
print_twice!(i * 10):
  70
  70
FIB10 = 55, buf.len() = 8
```

**Проверено:** rustc 1.98.1 (`--edition 2021`), macOS.

`macro_rules!` исправляет все три проблемы C, не отказываясь от макросов.
Фрагмент `$x:expr` подставляется как уже разобранное выражение, поэтому
приоритет сохраняется ([Reference: Forwarding a matched fragment](https://doc.rust-lang.org/reference/macros-by-example.html#forwarding-a-matched-fragment)).
Двойное вычисление устраняет сам автор макроса через `let`. Имена, введённые
внутри макроса, не видны в месте вызова и не перекрывают его имена
([Reference: Hygiene](https://doc.rust-lang.org/reference/macros-by-example.html#r-macro.decl.hygiene)).
Вычисления при компиляции — отдельный механизм `const fn`
([Reference: Constant evaluation](https://doc.rust-lang.org/reference/const_eval.html#r-const-eval.const-fn)),
а обобщения — третий механизм, трейты с явными ограничениями. Макросы Rust
умеют то, чего comptime не умеет: вводить новый синтаксис (`vec![...]`,
DSL в процедурных макросах).

### Lisp: код как данные

```lisp title="macros.lisp"
--8<-- "src/zig-comptime/macros.lisp"
```

```text title="Вывод (ожидаемый)"
(4 4)
```

**Не запускалось:** реализации Common Lisp в окружении нет; вывод по
[CLHS: DEFMACRO](https://www.lispworks.com/documentation/HyperSpec/Body/m_defmac.htm)
и [CLHS: GENSYM](https://www.lispworks.com/documentation/HyperSpec/Body/f_gensym.htm):
`(incf i)` вычисляется один раз и возвращает 4.

В Lisp программа — это списки, поэтому макрос — обычная функция над списками,
выполняемая при компиляции. Это ближе всего к идее Zig «тот же язык в обеих
фазах», но результат макроса — новый *код*, а результат comptime-вычисления в
Zig — *значение* (число, массив, тип). Гигиены `defmacro` не даёт, её
обеспечивают вручную через `gensym`
([Steele, Gabriel, HOPL II](../languages/sources.md#hopl-lisp)).

| | C | C++ | Rust | Common Lisp | Zig |
|---|---|---|---|---|---|
| Механизм | текстовые макросы | шаблоны, `constexpr` | `macro_rules!`, `const fn`, трейты | `defmacro` | `comptime` |
| Единица работы | токены | типы и значения | деревья токенов | формы (списки) | значения, включая типы |
| Гигиена | нет | не нужна (не макросы) | да, для локальных имён | вручную (`gensym`) | не нужна (не макросы) |
| Тот же язык в обеих фазах | нет | частично (`constexpr`) | частично (`const fn`) | да | да |
| Новый синтаксис | ограниченно | нет | да | да | нет |

## Что взять в свой язык

**Свёртка констант — это маленький comptime.** Оптимизация «вычислить
`2 * 3 + 1` при компиляции» ([лекция «Оптимизация кода»](../lectures/html/11-optimizaciya-koda.html))
реализуется обходом AST: если оба операнда — литералы, заменить узел
результатом. Это уже интерпретатор выражений, работающий внутри компилятора.
Проверьте, что он ведёт себя так же, как сгенерированный код: деление на ноль,
переполнение и порядок вычислений должны совпадать, иначе программа будет
давать разный результат в зависимости от того, свернул ли компилятор выражение.

**Интерпретатор AST можно переиспользовать.** Многие студенты сначала пишут
интерпретатор дерева для отладки, а затем генератор кода. Если сохранить
интерпретатор, его можно вызывать из семантического анализатора: для
инициализаторов глобальных констант (требование «инициализирующее выражение
может быть константным», [требования практикума](../labs/index.md#trebovaniya),
п. 2.1), для размеров массивов, для `assert` при компиляции. Остаётся решить,
какие узлы разрешены в этом режиме: запретить `read()`/`write()` и вызовы
внешних функций — как в Zig с `comptime call of extern function`.

**Двухфазность — это атрибут в AST.** Для каждого выражения семантический
анализатор может вычислить флаг «известно при компиляции». Правила простые:
литерал — да; имя константы с известным инициализатором — да; операция —
если все операнды да; вызов — если функция чистая и все аргументы да. Этот
флаг — синтезируемый атрибут в терминах атрибутных грамматик
([лекция «Синтаксически управляемая трансляция»](../lectures/html/12-sintaksicheski-upravlyaemaya-translyaciya.html)).

**Staging вместо макросов.** Если хочется обобщений, не добавляйте в
грамматику шаблоны: разрешите параметр, помеченный как известный при
компиляции, и порождайте копию функции для каждого набора таких аргументов.
Кеш инстанцирований — словарь «(функция, comptime-аргументы) → сгенерированная
функция». Это мономорфизация в самой простой форме, и она хорошо ложится на
генерацию для JVM, CIL, LLVM и WASM.

**Не делайте текстовые макросы.** Если вариант просит «макросы» или
`#define`, реализуйте их на уровне AST и выводите диагностику по исходным
позициям. Пример `macros.c` показывает, что текстовая подстановка создаёт
ошибки, которые пользователь не видит в своём коде.

## Упражнение

1. Предскажите результат замены в `reflection.zig` строки
   `inline for (@typeInfo(T).@"struct".fields) |field|` на обычный
   `for (...) |field|`. Будет ли программа компилироваться и почему?

    ??? question "Ответ"
        Нет. В обычном цикле `field` — переменная времени выполнения, а её
        поле `field.type` имеет тип `type`, который существует только при
        компиляции; `@typeName` требует comptime-аргумента. Компилятор сообщит,
        что значение должно быть известно при компиляции (формулировки
        различаются между выпусками). Именно поэтому
        [inline for](https://ziglang.org/documentation/0.16.0/#inline-for)
        описан как способ «использовать типы как значения первого класса».

2. Добавьте в свой компилятор свёртку констант с проверкой: объявление
   `const int N = 2 + 3 * 4;` должно порождать в целевом коде одну загрузку
   константы `14`. Затем разрешите вызов пользовательской функции без побочных
   эффектов в инициализаторе константы, интерпретируя её тело при компиляции.
   Какие узлы AST ваш интерпретатор отклонит и с каким сообщением?

## Источники

- [Zig 0.16.0 Language Reference](https://ziglang.org/documentation/0.16.0/) ([в каталоге](../languages/sources.md#zig-langref)): [comptime](https://ziglang.org/documentation/0.16.0/#comptime), [Compile-Time Parameters](https://ziglang.org/documentation/0.16.0/#Compile-Time-Parameters), [Compile-Time Expressions](https://ziglang.org/documentation/0.16.0/#Compile-Time-Expressions), [Generic Data Structures](https://ziglang.org/documentation/0.16.0/#Generic-Data-Structures), [Case Study: print in Zig](https://ziglang.org/documentation/0.16.0/#Case-Study-print-in-Zig), [inline for](https://ziglang.org/documentation/0.16.0/#inline-for), [@typeInfo](https://ziglang.org/documentation/0.16.0/#typeInfo), [@compileError](https://ziglang.org/documentation/0.16.0/#compileError), [@setEvalBranchQuota](https://ziglang.org/documentation/0.16.0/#setEvalBranchQuota), [C Macros](https://ziglang.org/documentation/0.16.0/#C-Macros), [Zen](https://ziglang.org/documentation/0.16.0/#Zen).
- [Zig Overview](https://ziglang.org/learn/overview/): «Small, simple language», «Compile-time reflection and compile-time code execution».
- [cppreference: Replacing text macros (C)](https://en.cppreference.com/w/c/preprocessor/replace); [cppreference: constexpr specifier](https://en.cppreference.com/w/cpp/language/constexpr).
- The Rust Reference: [Macros By Example](https://doc.rust-lang.org/reference/macros-by-example.html), [Constant evaluation](https://doc.rust-lang.org/reference/const_eval.html).
- Common Lisp HyperSpec: [DEFMACRO](https://www.lispworks.com/documentation/HyperSpec/Body/m_defmac.htm), [GENSYM](https://www.lispworks.com/documentation/HyperSpec/Body/f_gensym.htm).
- B. Stroustrup. [A History of C++](../languages/sources.md#hopl-cpp). HOPL II, 1993; G. Steele, R. Gabriel. [The Evolution of Lisp](../languages/sources.md#hopl-lisp). HOPL II, 1993.
- Карточка языка: [Zig](../languages/zig.md). Словарь: [метапрограммирование](../languages/glossary.md#syntax-metaprogramming), [гигиена макросов](../languages/glossary.md#syntax-macro-hygiene), [параметрический полиморфизм](../languages/glossary.md#subprograms-generics), [реализация обобщений](../languages/glossary.md#subprograms-generic-mechanism), [проверка типов](../languages/glossary.md#typing-checking).
