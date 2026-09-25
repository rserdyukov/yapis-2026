---
publish: true
title: "JavaScript: цена обратной совместимости"
description: "Выпущенное в веб поведение почти нельзя убрать, поэтому JavaScript исправляет ошибки только добавлением новых конструкций, а старые остаются в языке навсегда."
languages: [javascript]
concepts: [typing.conversions, scope.constructs, syntax.statement_terminator, typing.checking, evaluation.tail_calls]
---

# JavaScript: цена обратной совместимости

*«Don't break the Web»: язык, который нельзя перевыпустить, может только расти.*

## Проблема

Страница в вебе хранится как исходный текст и заново интерпретируется
браузером при каждом открытии. Многие страницы никто не сопровождает, но
ими пользуются. Если новая версия браузера меняет смысл старого кода,
сломанной оказывается чужая страница, а пользователь уходит в другой
браузер. Аллен Вирфс-Брок и [Брендан Эйх](../languages/people.md#eich)
описывают это как «теорию игр браузеров»: изменения, ломающие код (даже
исправления ошибок), отпугивают пользователей, новый браузер обязан
повторять уже существующее, а первый, кто попробует новое, может
потерять долю рынка. Ограничение формулируется лозунгом «Don't break the
Web!» ([hopl-javascript](../languages/sources.md#hopl-javascript),
§13.3 «Browser Game Theory»).

В обычном языке ошибку проектирования исправляют новой версией, и
пользователи мигрируют. У JavaScript нет момента, когда все программы
мира перекомпилируют: сайт 1996 года открывается сегодняшним браузером.
Первая попытка версионирования провалилась быстро. В JavaScript 1.2 Эйх
убрал большинство неявных приведений из `==` и рассчитывал, что атрибут
версии тега `<script>` отделит старое поведение от нового; но уже к
выходу 1.2 таким версионированием веб-разработчикам было трудно
управлять, и в стандарт это изменение не попало
([hopl-javascript](../languages/sources.md#hopl-javascript), §5).

Первый прототип был написан за десять дней в мае 1995 года
([hopl-javascript](../languages/sources.md#hopl-javascript), §1–2).
Решения, принятые в спешке, получили миллионы зависимых страниц раньше,
чем их успели пересмотреть. Эта статья — о том, во что превращается язык,
в котором каждое решение окончательно.

## Идея

Раз удалить ничего нельзя, язык развивается только добавлением:

- неудачное `==` не исправляют, а добавляют `===` и `Object.is`;
- `var` с областью видимости функции остаётся, рядом появляются `let` и
  `const` с блочной областью;
- исправления, меняющие смысл существующего кода, собраны в
  **строгий режим** (strict mode) — диалект, который код включает сам
  директивой `"use strict"` или тем, что он модуль или тело класса;
- новые имена методов выбирают так, чтобы не задеть старые сайты.

При подготовке ES6 комитет TC39 думал о явных переключателях для новых
возможностей, но в 2012 году принял подход «One JavaScript» (1JS):
программисты и разработчики движков должны думать об одном языке «без
режимов, версий и диалектов». Ломающие изменения ограничили кодом внутри
модулей, остальные возможности переделали так, чтобы они вели себя
одинаково везде ([hopl-javascript](../languages/sources.md#hopl-javascript),
§21.1.5). Кроме строгого режима, прагм версий в языке нет.

Правила совместимости теперь часть спецификации. В
[ECMA-262](https://tc39.es/ecma262/) есть приложение
[B «Additional ECMAScript Features for Web Browsers»](https://tc39.es/ecma262/#sec-additional-ecmascript-features-for-web-browsers):
устаревшие возможности (восьмеричные литералы вида `010`, особая
семантика объявлений функций в блоках и др.), которые браузер обязан
поддерживать, потому что на них опираются существующие страницы.

**Проверено:** все примеры запускались в Node.js 22.23.3 (V8), macOS.
Файлы с расширением `.cjs` Node исполняет как скрипты CommonJS — это
нестрогий код, если внутри нет `"use strict"`; файл `.mjs` — модуль ES,
он всегда строгий. Это важно: одни и те же строки в `.cjs` и `.mjs` ведут
себя по-разному.

## Как это работает

### Нестрогое равенство

Алгоритм [IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal)
приводит операнды разных типов: булево — к числу, строку — к числу,
объект — к примитиву; `null` равен только `undefined`.
[IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal) (`===`)
ничего не приводит.

```js title="equality.cjs"
--8<-- "src/javascript-compatibility/equality.cjs:table"
```

```text title="Вывод"
0 == ''            true   === false
0 == '0'           true   === false
'' == '0'          false  === false
false == '0'       true   === false
false == ''        true   === false
null == undefined  true   === false
null == 0          false  === false
null == false      false  === false
[] == false        true   === false
[] == ![]          true   === false
[0] == false       true   === false
'\n' == 0          true   === false
NaN == NaN         false  === false
```

Первые три строки показывают, что `==` нетранзитивно: `0 == ''` и
`0 == '0'`, но `'' != '0'`. `[] == ![]` истинно, потому что `![]` — это
`false` (объект всегда истинен), а `[]` приводится к `''`, затем к `0`.
Строка из пробельных символов приводится к `0`.

### `typeof null` и `NaN`

```js title="equality.cjs"
--8<-- "src/javascript-compatibility/equality.cjs:nan"
```

```text title="Вывод"
object undefined function
false -1 true
true false true
```

`typeof null === "object"` Эйх объясняет протекающей абстракцией первой
реализации: `null` кодировался тем же внутренним тегом, что и объекты, и
`typeof` возвращал `"object"` без особого случая. С тех пор проверка
«это объект?» требует `x !== null && typeof x === "object"`
([hopl-javascript](../languages/sources.md#hopl-javascript), §3.2).

`NaN !== NaN` — не наследие JavaScript, а требование IEEE 754, которое
соблюдают и другие языки. Совместимость проявилась в другом: `indexOf`
использует `===` и не находит `NaN`, а добавленный позже `includes`
сравнивает по алгоритму SameValueZero и находит. Старый метод исправить
нельзя, поэтому рядом появился новый с другой семантикой, а для точного
сравнения — [`Object.is`](https://tc39.es/ecma262/#sec-object.is)
(алгоритм [SameValue](https://tc39.es/ecma262/#sec-samevalue): `NaN`
равен себе, `0` и `-0` различаются).

### Вставка точки с запятой

Точка с запятой в JavaScript формально обязательна, но правила
[автоматической вставки](https://tc39.es/ecma262/#sec-automatic-semicolon-insertion)
(Automatic Semicolon Insertion, ASI) добавляют её, если следующий токен
не может продолжить оператор. Уже справочник Netscape 2.0 писал примеры
без точек с запятой, и ASI до сих пор спорная тема
([hopl-javascript](../languages/sources.md#hopl-javascript), §3.1).

```js title="asi.cjs"
--8<-- "src/javascript-compatibility/asi.cjs"
```

```text title="Вывод"
undefined { port: 80 }
11
21
```

После `return` грамматика запрещает перевод строки (это
«restricted production»), поэтому парсер вставил `;` и функция
вернула `undefined`, а `{ port: 80 }` стал блоком с меткой `port`.
Обратная ловушка: строка, начинающаяся с `[` или `(`, продолжает
предыдущий оператор, и без ведущей `;` получилось бы `a[10, 20].forEach(...)`.
Спецификация сама разбирает такие случаи в разделе
[Interesting Cases of ASI](https://tc39.es/ecma262/#sec-interesting-cases-of-automatic-semicolon-insertion).

### `var` против `let`

`var` объявляет переменную на всю функцию и «поднимает» (hoisting)
объявление в её начало. `let` и `const`, добавленные в ES2015, имеют
блочную область и создают новую переменную на каждой итерации `for`.

```js title="scope.cjs"
--8<-- "src/javascript-compatibility/scope.cjs:loop"

--8<-- "src/javascript-compatibility/scope.cjs:hoist"
```

```text title="Вывод"
[ 3, 3, 3 ] [ 0, 1, 2 ]
number undefined
undefined
ReferenceError: Cannot access 'l' before initialization
```

Все три замыкания с `var` видят одну переменную `i`, которая к моменту
вызова равна 3. Изменить семантику `var` было нельзя — на неё опирается
весь существующий код, — поэтому появилось второе ключевое слово.
Обращение к `let` до объявления — ошибка («временная мёртвая зона»), к
`var` — `undefined`.

### `this` определяется вызовом

В обычной функции `this` зависит от того, *как* её вызвали
([OrdinaryCallBindThis](https://tc39.es/ecma262/#sec-ordinarycallbindthis)).
При вызове без получателя нестрогий код подставляет глобальный объект,
строгий — оставляет `undefined`. Стрелочные функции (ES2015) не имеют
своего `this` и берут его из окружающей функции.

```js title="this.cjs"
--8<-- "src/javascript-compatibility/this.cjs:callback"

--8<-- "src/javascript-compatibility/this.cjs:detached"
```

```text title="Вывод"
function: true undefined
function: true undefined
arrow: 2
function: true undefined
function: true undefined
arrow: NaN
global n: NaN
strict: TypeError: Cannot read properties of undefined (reading 'n')
```

Отцепленный метод в нестрогом коде молча работает с глобальным объектом
и создаёт там свойство `n` со значением `NaN`. В строгом коде та же
ошибка сразу видна как `TypeError`.

### Строгий режим — опциональный диалект

Строгий режим появился в ES5 (2009). По воспоминаниям авторов, многие
неудачные особенности нельзя было исправить безусловно — это изменило бы
поведение существующего кода, — поэтому разработчикам дали возможность
явно включить диалект с исправлениями в новом или обновлённом коде. В
качестве переключателя выбрали строку `"use strict";`: для ES3 это
допустимый оператор-выражение без побочных эффектов, так что старые
движки его просто игнорируют
([hopl-javascript](../languages/sources.md#hopl-javascript), §20.1.1).

```js title="strict.cjs"
--8<-- "src/javascript-compatibility/strict.cjs:modes"
```

```text title="Вывод"
sloppy: 42 1
strict: ReferenceError: undeclared2 is not defined
strict: TypeError: Cannot assign to read only property 'x' of object '#<Object>'
```

Устаревшие конструкции — `with` и восьмеричный литерал `010` —
работают в нестрогом коде и являются синтаксическими ошибками в строгом
([Strict Mode Code](https://tc39.es/ecma262/#sec-strict-mode-code),
[The Strict Mode of ECMAScript](https://tc39.es/ecma262/#sec-strict-mode-of-ecmascript)):

```js title="strict.cjs"
--8<-- "src/javascript-compatibility/strict.cjs:legacy"
```

```text title="Вывод"
with (Math) return PI                 -> 3.141592653589793
return 010                            -> 8
'use strict'; return 010              -> SyntaxError: Octal literals are not allowed in strict mode.
'use strict'; with (Math) return PI   -> SyntaxError: Strict mode code may not include a with statement
```

Модули ES строги без директивы — один из немногих случаев, когда новый
контекст позволил сменить умолчание:

```js title="module.mjs"
--8<-- "src/javascript-compatibility/module.mjs"
```

```text title="Вывод"
module: ReferenceError: undeclared is not defined
this at top level: undefined
```

### Мелкие наследия

```js title="legacy.cjs"
--8<-- "src/javascript-compatibility/legacy.cjs"
```

```text title="Вывод"
8 Fri Sep 25 2026
3 false [ 10, <1 empty item>, 30 ] -1 true
99 1
[ 1, 2, [ 3 ] ] undefined undefined function
```

- Сентябрь — месяц `8`: `Date` в JavaScript 1.0 был прямым переносом
  `java.util.Date` из Java 1.0, «вместе с ошибками», включая нумерацию
  месяцев с 0 ([hopl-javascript](../languages/sources.md#hopl-javascript),
  §3.5).
- `[1, , 3]` содержит «дыру»: индекса `1` нет вовсе (`1 in holes` — `false`),
  `map` её пропускает, `indexOf(undefined)` не находит, а `includes` —
  находит.
- В нестрогой функции `arguments[0]` связан с параметром `a`, в строгой —
  нет ([Arguments Exotic Objects](https://tc39.es/ecma262/#sec-arguments-exotic-objects)).
- `flat` и `includes` названы так не по вкусу. Предложение
  `Array.prototype.flatten` дошло до Stage 3, но при включении в Firefox
  Nightly сломало сайты с библиотекой MooTools: она копирует перечислимые
  свойства `Array.prototype` в свой `Elements.prototype`, а нативный
  `flatten` неперечислим. В мае 2018 года TC39 переименовал метод во
  `flat` ([SmooshGate FAQ](https://developer.chrome.com/blog/smooshgate)).
  Раньше, в ноябре 2014 года, по той же причине `contains` стал
  `includes` ([репозиторий предложения](https://github.com/tc39/proposal-Array.prototype.includes)).

### Хвостовые вызовы: спецификация против движков

ES2015 требует правильных хвостовых вызовов (proper tail calls) в
строгом коде ([Tail Position Calls](https://tc39.es/ecma262/#sec-tail-position-calls)).
Авторы HOPL отмечают, что это оказалось спорной возможностью: минимум
один крупный движок её реализовал, другие отказались
([hopl-javascript](../languages/sources.md#hopl-javascript), §21.3.6).
Требование остаётся в тексте стандарта, но переносимый код на него
полагаться не может.

```js title="tailcall.cjs"
--8<-- "src/javascript-compatibility/tailcall.cjs"
```

```text title="Вывод"
1000 done
1000000 RangeError: Maximum call stack size exceeded
```

Это обратная сторона совместимости: если убрать требование из стандарта
трудно, а реализовать его движки не хотят, спецификация и реальность
расходятся.

## Цена

**Язык только растёт.** В нём одновременно `var`/`let`/`const`, `==`/
`===`/`Object.is`, `indexOf`/`includes`, функции с динамическим `this` и
стрелки с лексическим, нестрогий и строгий диалекты. Новичку приходится
учить и то, чем пользоваться не надо, — хотя бы чтобы читать чужой код.

**Правила выбора становятся социальными.** Язык не запрещает `==` и
`var`, это делают линтеры и стайлгайды. Граница между «JavaScript» и
«JavaScript, который принято писать» проходит вне спецификации.

**Сложность реализации.** Движок обязан поддерживать приложение B,
`with`, связанный `arguments`, два режима семантики с разными правилами
для `this` и присваивания. Разработчик парсера реализует ASI и
«restricted productions» — ограничения на переносы строк, которых нет в
большинстве грамматик.

**Проектирование с оглядкой на чужой код.** Имя нового метода выбирают,
проверяя, не использует ли его какая-нибудь библиотека десятилетней давности.
Хорошее имя может оказаться недоступным навсегда.

**Но и выигрыш реален.** Страница, написанная двадцать лет назад, работает
сегодня; код можно переводить на строгий режим по одной функции;
библиотека, использующая новые возможности, совместима со старыми
сценариями на той же странице. Альтернативы — см. ниже — стоили другим
языкам лет раздробленной экосистемы.

## Сравнение

| Язык | Стратегия | Цена |
|---|---|---|
| JavaScript | ничего не удалять; исправления — новыми конструкциями и opt-in строгим режимом | язык копит устаревшие конструкции |
| Python 2 → 3 | один намеренно несовместимый выпуск | годы параллельной поддержки двух языков |
| Rust | редакции (editions): несовместимые изменения включаются на уровне крейта | компилятор поддерживает все редакции сразу |
| Java | строгая бинарная совместимость, осторожные ключевые слова | медленное исправление ошибок проектирования |

**Python 3.0** (декабрь 2008) — по словам «What's New» — «первый
намеренно несовместимый с прошлым выпуск Python»: `print` стал функцией,
`1/2` возвращает `0.5` и т. д.
([What's New In Python 3.0](https://docs.python.org/3/whatsnew/3.0.html)).
Поддержку Python 2.7 продлили до 2020 года, чтобы не оставить тех, кто
не успел мигрировать ([PEP 373](https://peps.python.org/pep-0373/)).
Двенадцать лет сосуществования двух веток — цена одного перевыпуска.

**Rust** делает несовместимые изменения опциональными: каждый крейт
указывает редакцию в `Cargo.toml`, и главное правило — крейты разных
редакций должны без проблем работать вместе. Так в язык добавили ключевые
слова `async`/`await`, не сломав код, где `async` был именем переменной
([Edition Guide](https://doc.rust-lang.org/edition-guide/editions/index.html)).
Это ровно то, от чего отказался JavaScript в 1JS: режимы, выбираемые
единицей компиляции. У Rust есть то, чего нет в вебе, — компилятор,
который видит весь код до запуска.

**Java** закрепляет правила бинарной совместимости в спецификации: глава 13
JLS перечисляет изменения класса, которые не ломают уже скомпилированные
клиенты ([JLS §13](https://docs.oracle.com/javase/specs/jls/se21/html/jls-13.html)).
Как и JavaScript, Java почти ничего не удаляет из языка; в отличие от
него, у неё есть явная версия исходного кода (`--release`) у компилятора.

## Что взять в свой язык

1. **Решения становятся постоянными в момент, когда появляются
   пользователи.** Даже у учебного языка это наступает быстро: тесты,
   примеры в отчёте, программы однокурсников. Спорные вещи — неявные
   приведения, правила областей видимости, значимость перевода строки —
   решайте до того, как на них напишут код.
2. **Предусмотрите механизм версий заранее.** Варианты: номер версии
   грамматики в начале файла (`#lang v2`), опции компилятора, редакции на
   уровне модуля, прагмы в стиле `"use strict"`. JavaScript показал, что
   встроить переключатель задним числом можно только через конструкцию,
   которая уже была допустима и ничего не делала.
3. **Не делайте перевод строки «иногда значимым».** ASI требует от парсера
   знать, какой токен может продолжить оператор, и вводит ограничения на
   переносы. Если в вашей грамматике перевод строки завершает оператор,
   сделайте это правилом лексера/грамматики, а не восстановлением после
   ошибки; если не завершает — требуйте `;`.
4. **Предпочитайте явное приведение.** Каждое неявное приведение в
   семантическом анализе — строка в таблице, которую придётся
   поддерживать вечно. Проще запретить `int == string` ошибкой типа.
5. **Документируйте версию грамматики в лабораторной.** Укажите в отчёте
   и в заголовке `.g4`, какой вариант языка реализован, и храните тесты
   для каждой версии: если вы меняете смысл конструкции, старые тесты
   покажут, чьи программы сломались.

## Упражнение

1. Предскажите вывод, затем проверьте `node file.cjs`:

    ```js
    function f() {
      return
        1 + 2
    }
    var x = 1
    {
      var x = 2
    }
    let y = 1
    {
      let y = 2
    }
    console.log(f(), x, y, [] + [], [] + {}, null == 0, null >= 0)
    ```

    ??? question "Ответ"
        `undefined 2 1  [object Object] false true`. После `return`
        вставлена `;`. `var` не знает блоков, `let` знает. `[] + []` —
        пустая строка, `[] + {}` — `"[object Object]"`. `null == 0`
        ложно (особое правило `==` для `null`), а `null >= 0` истинно:
        отношения приводят `null` к числу `0`.

2. В грамматике вашего языка добавьте директиву версии в начало
   программы (`version 2;`) и одно изменение семантики, зависящее от неё
   (например, в версии 2 целочисленное деление `/` становится
   вещественным). Где в компиляторе должна проверяться версия: в
   парсере, семантическом анализе или генераторе? Что будет при
   компоновке модулей разных версий?

## Источники

- A. Wirfs-Brock, B. Eich. JavaScript: The First 20 Years. Proc. ACM
  Program. Lang. 4, HOPL IV, 2020 —
  [hopl-javascript](../languages/sources.md#hopl-javascript). Использованы §2 (прототип),
  §3.1–3.5 (ASI, `typeof null`, `Date`), §5 (JavaScript 1.2 и `==`),
  §13.3 (Browser Game Theory), §20.1.1 (Strict Mode), §21.1.5 (One
  JavaScript), §21.3.6 (proper tail calls).
- [ECMA-262 (текущий черновик)](https://tc39.es/ecma262/):
  [IsLooselyEqual](https://tc39.es/ecma262/#sec-islooselyequal),
  [IsStrictlyEqual](https://tc39.es/ecma262/#sec-isstrictlyequal),
  [SameValue](https://tc39.es/ecma262/#sec-samevalue),
  [Automatic Semicolon Insertion](https://tc39.es/ecma262/#sec-automatic-semicolon-insertion),
  [Strict Mode Code](https://tc39.es/ecma262/#sec-strict-mode-code),
  [The Strict Mode of ECMAScript](https://tc39.es/ecma262/#sec-strict-mode-of-ecmascript),
  [The with Statement](https://tc39.es/ecma262/#sec-with-statement),
  [Tail Position Calls](https://tc39.es/ecma262/#sec-tail-position-calls),
  [Annex B](https://tc39.es/ecma262/#sec-additional-ecmascript-features-for-web-browsers).
- M. Bynens. [SmooshGate FAQ](https://developer.chrome.com/blog/smooshgate), 2018.
- [tc39/proposal-Array.prototype.includes](https://github.com/tc39/proposal-Array.prototype.includes) — переименование `contains` → `includes`.
- [What's New In Python 3.0](https://docs.python.org/3/whatsnew/3.0.html),
  [PEP 373](https://peps.python.org/pep-0373/).
- [The Rust Edition Guide — What are editions?](https://doc.rust-lang.org/edition-guide/editions/index.html)
- [JLS SE 21, Chapter 13 — Binary Compatibility](https://docs.oracle.com/javase/specs/jls/se21/html/jls-13.html).
- Карточка [JavaScript](../languages/javascript.md); понятия словаря:
  [преобразования типов](../languages/glossary.md#typing-conversions),
  [области видимости](../languages/glossary.md#scope-constructs),
  [завершение оператора](../languages/glossary.md#syntax-statement-terminator),
  [проверка типов](../languages/glossary.md#typing-checking),
  [хвостовые вызовы](../languages/glossary.md#evaluation-tail-calls).
- Смежная статья сада: [Lua: метатаблицы, язык как конструктор](lua-metatables.md).
