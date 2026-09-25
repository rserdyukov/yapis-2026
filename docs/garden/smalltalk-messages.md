---
publish: true
title: "Smalltalk: всё есть сообщение"
description: "Если каждое значение — объект, а каждое вычисление — посылка сообщения, то условия, циклы и даже классы перестают быть синтаксисом и становятся библиотекой."
languages: [smalltalk, python, javascript]
concepts: [abstraction.dispatch, typing.compatibility, control.selection, subprograms.closures, syntax.metaprogramming]
---

# Smalltalk: всё есть сообщение

*Одна операция — «послать объекту сообщение» — заменяет в Smalltalk арифметику, условия, циклы и работу с классами; грамматика от этого сжимается до нескольких правил, а сложность переезжает в среду исполнения.*

## Проблема

В большинстве языков есть два мира. В первом живут встроенные вещи: числа, операторы `+` и `*`, `if`, `while`, объявление класса. У каждой из них своя грамматическая форма и свой кусок компилятора. Во втором мире живёт то, что написал программист: функции, классы, методы. Встроенное нельзя переопределить, программное нельзя сделать таким же удобным, как встроенное. В Java `int` — не объект, у него нет методов, и в коллекцию его приходится упаковывать в `Integer`; `if` — оператор, и нельзя написать свой `unless`, который выглядел бы так же.

Для автора компилятора это означает длинную грамматику: десятки видов операторов, таблица приоритетов, отдельная проверка типов для каждого вида конструкций. Для пользователя языка — швы: одни значения ведут себя как объекты, другие нет.

Группа Алана Кэя ([kay](../languages/people.md#kay)) в Xerox PARC пошла от противоположной точки. В своей истории Smalltalk Кэй перечисляет шесть идей, на которых сошлись к Smalltalk-72; первые две — «Everything is an object» и «Objects communicate by sending and receiving messages (in terms of objects)», а четвёртая — «Every object is an instance of a class (which must be an object)» ([hopl-smalltalk](../languages/sources.md#hopl-smalltalk)). Там же он пишет, что из этих правил следует: классы — объекты. Smalltalk-80, описанный Адель Голдберг ([goldberg](../languages/people.md#goldberg)) и Дэвидом Робсоном в «синей книге» ([smalltalk-80-blue-book](../languages/sources.md#smalltalk-80-blue-book)), довёл эту программу до конца: второго мира в нём нет.

## Идея

Любое значение — объект: `3`, `true`, `nil`, строка, блок кода, класс, метод, даже контекст выполнения. Любое вычисление — посылка сообщения (message send): у выражения есть получатель (receiver), селектор (selector — имя сообщения) и аргументы. Какой код выполнится, решает не вызывающий, а получатель: виртуальная машина ищет метод с этим селектором в классе получателя, затем в его суперклассах. Это одиночная динамическая диспетчеризация ([abstraction.dispatch](../languages/glossary.md#abstraction-dispatch)). Если метод не нашёлся, получателю посылается ещё одно сообщение — `doesNotUnderstand:` с описанием непонятого сообщения в качестве аргумента (Blue Book, гл. 4; [Pharo by Example 9, «The Pharo object model»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/PharoObjectModel/PharoObjectModel.md)).

Для записи сообщений в языке всего три формы:

| Форма | Пример | Селектор | Аргументов |
|---|---|---|---|
| унарная (unary) | `3 factorial` | `factorial` | 0 |
| бинарная (binary) | `3 + 4` | `+` | 1 |
| ключевая (keyword) | `2 raisedTo: 6 modulo: 10` | `raisedTo:modulo:` | по одному на каждое ключевое слово |

К ним добавляются присваивание `x := выражение`, возврат `^ выражение`, каскад `;` (несколько сообщений одному получателю), литералы и блоки `[ :x | … ]`. Зарезервированных слов шесть, и все они — псевдопеременные: `self`, `super`, `nil`, `true`, `false`, `thisContext` ([PBE9, «Syntax in a nutshell»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md)). Ни `if`, ни `while`, ни `class` в этом списке нет. Шпаргалка Pharo укладывает весь синтаксис и объектную модель в две страницы ([Pharo Cheat Sheet](https://files.pharo.org/media/pharoCheatSheet.pdf)); синтаксис помещается на открытке — известный пример.

Приоритет задан не операциями, а формой сообщения. Blue Book (гл. 2, раздел «Parsing») формулирует пять правил: унарные разбираются слева направо; бинарные слева направо; бинарные старше ключевых; унарные старше бинарных; скобки старше всего. Про бинарные там сказано прямо: «All binary selectors have the same precedence; only the order in which they are written matters».

## Как это работает

Smalltalk на машине, где писалась статья, не установлен, поэтому примеры на Smalltalk приведены как выражения для Playground в Pharo с ожидаемым результатом после `>>>`; результат взят из Blue Book и Pharo by Example. Контрастные примеры на Python и JavaScript запущены.

### 1. Приоритет по форме, а не по смыслу

```smalltalk title="expressions.st"
--8<-- "src/smalltalk-messages/expressions.st:precedence"
```

**Не запускалось:** вывод по Blue Book, гл. 2 «Expression Syntax», раздел «Parsing», и [PBE9, «Understanding message syntax»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/UnderstandingMessage/UnderstandingMessage.md) (там есть `3 + 4 * 5 >>> 35` и `3 + 4 factorial >>> 27`).

`3 + 4 * 2` — это два бинарных сообщения: сначала `3` получает `+ 4` и отвечает `7`, затем `7` получает `* 2`. Для `+` и `*` у парсера нет особого знания: это просто селекторы, и пользовательский класс может определить `*` для матриц или `@` для точек, и они будут разбираться так же. Цена — арифметика «не как в школе»: PBE9 прямо называет это «the price to pay for the simplicity of the model».

Чтобы увидеть правило в работе, достаточно двадцати строк рекурсивного спуска. Каждый уровень грамматики — отдельная функция, и приоритет получается из того, какая функция какую вызывает:

```python title="binary_ltr.py"
--8<-- "src/smalltalk-messages/binary_ltr.py"
```

```text title="Вывод"
3 + 4 * 2                  => 14
3 + (4 * 2)                => 11
3 + 4 factorial            => 27
2 raisedTo: 1 + 2          => 8
3 max: 2 * 5 - 1           => 9
5 between: 1 and: 2 * 3    => True
Python: 3 + 4 * 2          => 11
```

**Проверено:** python3 3.14.7, macOS.

Сравните с грамматикой из [лекции о контекстно-свободных грамматиках](../lectures/html/05-kontekstno-svobodnye-grammatiki.html): для обычной арифметики нужны отдельные нетерминалы `expr`/`term`/`factor` на каждый уровень приоритета, и каждый новый оператор требует решения, куда его поставить. У Smalltalk уровней ровно три, и все бинарные операторы, включая будущие, попадают на один. Обратите внимание на `keyword_expr`: ключевые слова `between:` и `and:` не два сообщения, а части одного селектора `between:and:`, поэтому парсер собирает их в одно имя до вызова.

### 2. Условие — это сообщение объекту `true`

`ifTrue:ifFalse:` — обычное ключевое сообщение с двумя блоками-аргументами. Blue Book (гл. 14 «Kernel Support», раздел «Classes Boolean, True, and False») приводит реализацию целиком — у каждого из двух подклассов `Boolean` своя, в одну строку:

```smalltalk title="Boolean.st"
--8<-- "src/smalltalk-messages/Boolean.st:true-false"
```

**Не запускалось:** код по Blue Book, гл. 14 (в книге возврат обозначен стрелкой вверх) и [PBE9, «Basic classes»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/BasicClasses/BasicClasses.md), где те же два метода приведены в синтаксисе Pharo.

`true` — единственный экземпляр класса `True`, `false` — класса `False`. Выражение `x > 0` возвращает один из этих объектов, и поиск метода по классу получателя сам выбирает ветку. Blue Book подытоживает: механизм поиска сообщений даёт реализацию условного управления «with no additional primitive operations or circular definitions». Короткое замыкание `and:`/`or:` устроено так же: аргумент — блок, а вычислять его или нет, решает получатель.

```smalltalk title="Boolean.st"
--8<-- "src/smalltalk-messages/Boolean.st:and-or"
```

Блоки здесь обязательны: `[ … ]` — отложенное вычисление, объект, который выполнится, только когда получит `value`. Без блоков обе ветки вычислились бы до посылки сообщения, потому что аргументы вычисляются строго.

Та же схема переносится в любой язык с замыканиями. Здесь в «пользовательском» коде нет ни одного `if`, выбор делает диспетчеризация методов:

```python title="if_as_message.py"
--8<-- "src/smalltalk-messages/if_as_message.py"
```

```text title="Вывод"
abs(-5) = 5
abs(7)  = 7
(17 * 13 > 220) ifTrue: ... ifFalse: ...
  вычислен блок then
 -> bigger
false and: [...]  — блок не вычисляется:
 -> false
true and: [...]:
  вычислен блок arg
 -> false
true not not = true
```

**Проверено:** python3 3.14.7, macOS. (Внутри `Num.gt` стоит питоновский условный оператор — на каком-то уровне сравнение чисел должно дойти до машины; в Smalltalk это делает примитив `SmallInteger>>#>`.)

### 3. Циклы и замыкания — тоже сообщения

```smalltalk title="expressions.st"
--8<-- "src/smalltalk-messages/expressions.st:control"
```

**Не запускалось:** вывод по [PBE9, «Syntax in a nutshell», раздел «Conditionals and loops»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md) (примеры с `1024` и `to:do:` взяты оттуда) и Blue Book, гл. 2, раздел «Blocks».

`whileTrue:` посылается блоку-условию: Blue Book описывает, что блок-получатель посылает себе `value` и, пока ответ `true`, выполняет блок-аргумент. `to:do:` посылается числу, `do:`, `collect:`, `inject:into:` — коллекции. Поэтому цикл по дереву, по файлу или по результатам запроса к базе выглядит так же, как цикл по массиву: это вопрос того, какие методы есть у получателя, а не грамматики ([control.selection](../languages/glossary.md#control-selection), [control.iteration](../languages/glossary.md#control-iteration)).

Блок — полноценное замыкание ([subprograms.closures](../languages/glossary.md#subprograms-closures)): он захватывает переменные охватывающего контекста.

```smalltalk title="expressions.st"
--8<-- "src/smalltalk-messages/expressions.st:closure"
```

**Не запускалось:** поведение по PBE9, «Syntax in a nutshell» («Blocks also close over their definition environment»). Для Pharo, где блоки — `BlockClosure`. В исходном Smalltalk-80 блоки были `BlockContext`, делили временные переменные с методом и не были полностью реентерабельными, так что в нём этот пример мог бы вести себя иначе.

Ещё одна особенность блоков: `^` внутри блока возвращает из метода, в котором блок создан (нелокальный возврат). Именно это позволяет писать `detect:` или ранний выход из `do:` как библиотечный код.

### 4. `doesNotUnderstand:` — ловушка для прокси

Раз ошибка «метод не найден» — это обычное сообщение, его можно переопределить. PBE9 (глава «Reflection», раздел «Lightweight proxies») строит на этом логирующий прокси. Его класс наследует от `ProtoObject`, а не от `Object`, чтобы почти любое сообщение оказалось «непонятым»:

```smalltalk title="LoggingProxy.st"
--8<-- "src/smalltalk-messages/LoggingProxy.st:proxy"
```

```smalltalk title="LoggingProxy.st"
--8<-- "src/smalltalk-messages/LoggingProxy.st:proxy-use"
```

**Не запускалось:** код упрощён по [PBE9, «Reflection»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Reflection/Reflection.md) (в книге цель подменяется через `become:`). Там же названо ограничение: `class` и `yourself` отвечает сама VM, и прокси их не видит; `doesNotUnderstand:` не ловит посылки самому себе через `self`.

В Python ближайший аналог — `__getattr__`: он вызывается, только когда обычный поиск атрибута не нашёл имя, — ровно семантика `doesNotUnderstand:`.

```python title="proxy.py"
--8<-- "src/smalltalk-messages/proxy.py"
```

```text title="Вывод"
performing append(3)
performing append(4)
performing count(3)
count(3) = 1
invocation_count = 3
len(p): object of type 'LoggingProxy' has no len()
```

**Проверено:** python3 3.14.7, macOS.

Последняя строка показывает шов, которого в Smalltalk нет: `len(p)` не превращается в «сообщение» `__len__`, потому что неявные вызовы специальных методов ищутся в классе, в обход `__getattr__` ([Python Data Model, «Special method lookup»](https://docs.python.org/3/reference/datamodel.html#special-method-lookup)). В JavaScript `Proxy` перехватывает не только неизвестные, а вообще все обращения к свойствам:

```javascript title="proxy.js"
--8<-- "src/smalltalk-messages/proxy.js"
```

```text title="Вывод"
performing push(3)
performing push(4)
performing indexOf(4)
indexOf(4) = 1
length = 2
invocationCount = 3
```

**Проверено:** node 22.23.3, macOS.

### 5. Классы — тоже объекты, а у них тоже есть класс

```smalltalk title="expressions.st"
--8<-- "src/smalltalk-messages/expressions.st:everything-object"
```

**Не запускалось:** вывод по PBE9, «The Pharo object model» (`1 class >>> SmallInteger`, `20 factorial class >>> LargePositiveInteger`) и [PBE9, «Classes and metaclasses»](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Metaclasses/Metaclasses.md) (`Metaclass class class >>> Metaclass`); метаклассы Smalltalk-80 — Blue Book, гл. 5 «Metaclasses».

`SmallInteger` — объект, значит, у него есть класс. Это метакласс `SmallInteger class`, созданный автоматически и имеющий ровно один экземпляр. Метакласс — тоже объект; все метаклассы — экземпляры `Metaclass`, и цепочка замыкается: класс метакласса `Metaclass` снова `Metaclass`. «Методы класса» вроде `new` — обычные методы метакласса, и `Array new: 4` ищется по той же процедуре, что `3 + 4`, только начиная с `Array class`. Новый класс создаётся не декларацией, а сообщением `subclass:instanceVariableNames:…` суперклассу (оно видно в `LoggingProxy.st`).

Отсюда рефлексия ([syntax.metaprogramming](../languages/glossary.md#syntax-metaprogramming)): у класса можно спросить словарь методов, скомпилировать новый метод строкой и добавить его во время работы; `thisContext` даёт стек как цепочку объектов. Отладчик, браузер классов и сам компилятор написаны на Smalltalk и работают внутри того же образа (image) — сохранённого снимка всей памяти объектов. Кэй в HOPL II описывает, как в ранних версиях механизм контрольных точек (checkpointing) гарантировал «a recoverable image no more than a few seconds old»; Дэн Ингаллс ([ingalls](../languages/people.md#ingalls)) в HOPL IV прослеживает, как эта живая система дошла до Squeak ([hopl-smalltalk-squeak](../languages/sources.md#hopl-smalltalk-squeak)).

## Цена

**Производительность динамической посылки.** Если каждое `+` — поиск метода по селектору в цепочке классов, наивный интерпретатор медленный. Уже Blue Book (гл. 28, раздел «Send Bytecodes») добавляет в интерпретатор глобальный кэш методов (method cache), индексируемый парой «селектор, класс». Следующий шаг — встроенный кэш (inline cache) в месте вызова: запомнить класс получателя и найденный метод при прошлом вызове и при совпадении класса перейти сразу. Эта техника связана с работой Deutsch и Schiffman «Efficient implementation of the Smalltalk-80 system» (POPL 1984, [doi:10.1145/800017.800542](https://doi.org/10.1145/800017.800542)). Для Self Hölzle, Chambers и Ungar расширили её до полиморфных встроенных кэшей (PIC), в которых место вызова помнит несколько классов; кэш заодно собирает сведения о реальных типах, и компилятор использует их при перекомпиляции ([ECOOP'91](https://bibliography.selflanguage.org/pics.html)). То есть ответ на «сообщения медленные» — не отказ от модели, а JIT-компиляция с кэшами и сбором профиля. Что остаётся ценой: сложность виртуальной машины, прогрев и менее предсказуемое время выполнения, чем у прямого вызова.

**Честная модель не совсем честна.** Ради скорости компилятор Smalltalk-80 не посылает `ifTrue:ifFalse:`, `and:`, `or:`, `whileTrue:` и `whileFalse:`, если аргументы — литеральные блоки, а превращает их в условные переходы (Blue Book, гл. 26, раздел «Jump Bytecodes»). В Pharo к этому списку добавлены `to:do:`, `ifNil:` и другие (PBE9, «Reflection»). Следствие: переопределение `True>>ifTrue:ifFalse:` на такие места вызова не влияет, а в Pharo посылка `ifTrue:` не-логическому объекту в таком месте приводит не к `doesNotUnderstand:`, а к особому `mustBeBoolean` (PBE9, «Reflection»). Однородность модели — на уровне языка; реализация срезает углы там, где это важно.

**Образ вместо файлов.** Программа — это состояние образа: классы, объекты, открытые окна. Это даёт живую разработку (поправил метод в отладчике — продолжил выполнение), но плохо ложится на привычный мир: diff текстовых файлов, ревью, git, воспроизводимая сборка с нуля. Экспорт в текст (file-out) был в системе давно, в Pharo код хранят в git через Iceberg ([Pharo Documentation](https://pharo.org/documentation)), но граница «что в репозитории, а что только в образе» остаётся заботой разработчика.

**Непривычный синтаксис.** `3 + 4 * 2 = 14` удивляет каждого новичка. Ключевые селекторы читаются хорошо (`dict at: key put: value`), но точки-разделители, `^`, каскады и отсутствие привычных `if` поначалу тормозят. Модель и синтаксис неразделимы: если вернуть школьный приоритет, придётся ввести в парсер знание о конкретных селекторах.

**Нет статических типов.** Переменные не типизированы, пригодность объекта проверяется только при посылке ([typing.compatibility](../languages/glossary.md#typing-compatibility) — утиная типизация). Опечатка в селекторе обнаруживается при выполнении как `doesNotUnderstand:`. Среда отчасти компенсирует это (браузер предупреждает о неизвестных селекторах, есть поиск отправителей и реализаторов), но гарантий, как у статической проверки, нет, и автоматические рефакторинги опираются на эвристики.

## Сравнение

| | Smalltalk | Ruby | Objective-C | Java | Erlang |
|---|---|---|---|---|---|
| Числа — объекты | да | да | нет (C-скаляры), есть `NSNumber` | нет, примитивы + упаковка ([JLS §4.2](https://docs.oracle.com/javase/specs/jls/se21/html/jls-4.html#jls-4.2)) | нет классов вообще |
| `if` | сообщение `ifTrue:ifFalse:` | синтаксис | синтаксис C | оператор ([JLS §14.9](https://docs.oracle.com/javase/specs/jls/se21/html/jls-14.html#jls-14.9)) | выражение `if`/`case` |
| Вызов по имени во время работы | `perform:` | `send`, `public_send` | `performSelector:` | рефлексия `Method.invoke` | `apply/3` |
| Непонятое сообщение | `doesNotUnderstand:` | `method_missing` | пересылка через runtime (`forwardInvocation:`) | ошибка компиляции (при рефлексии — исключение) | не подошедшее ни к одному образцу сообщение остаётся в ящике |
| «Сообщение» значит | синхронный вызов с поздним связыванием | то же | то же | вызов метода | асинхронная посылка в почтовый ящик процесса |

**Ruby** ближе всех по объектной модели: `1.send(:+, 2)` возвращает `3`, у `nil` и `true` есть классы, а `method_missing` играет роль `doesNotUnderstand:` ([Ruby: `Object#send`](https://ruby-doc.org/3.3/Object.html), [`BasicObject#method_missing`](https://ruby-doc.org/3.3/BasicObject.html)). Но `if`, `while`, `class` в Ruby — синтаксис, а у операторов обычная таблица приоритетов: `3 + 4 * 2` равно 11.

**Objective-C** взял у Smalltalk синтаксис ключевых сообщений в квадратных скобках — `[dict setObject:v forKey:k]` — и динамическую посылку, но поверх C: `int` не объект, управляющие конструкции — из C. Своеобразное отличие — сообщения `nil`: в Smalltalk `nil` — объект класса `UndefinedObject`, и непонятное ему сообщение даёт `doesNotUnderstand:`; в Objective-C посылка сообщения `nil` разрешена и возвращает `nil`/0/`NO` ([Apple, «Working with Objects», раздел «Working with nil»](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithObjects/WorkingwithObjects.html)).

**Java** — пример «двух миров»: примитивы не объекты, `if` и `for` — операторы, виртуальный вызов разрешается через таблицу методов по статически известной сигнатуре.

**Erlang** использует то же слово в другом смысле. Там сообщение — асинхронная посылка значения в почтовый ящик другого процесса (`Pid ! Msg`), отправитель не ждёт ответа, а получатель выбирает сообщение сопоставлением с образцом. Посылка сообщения в Smalltalk синхронна и по сути является вызовом с поздним связыванием. Кэй в HOPL II описывает замысел как «thousands and thousands of computers all hooked together by a very fast network», и Erlang ближе к этой метафоре буквально; подробнее — в статье [Erlang: пусть падает](erlang-let-it-crash.md).

## Что взять в свой язык

**Однородная модель сжимает грамматику.** У выражений Smalltalk по сути пять продукций: первичное (литерал, переменная, блок, скобки), унарное, бинарное, ключевое сообщение и каскад, плюс присваивание и `^`. Если ваш язык разрешает пользовательские операторы, подумайте о правиле Smalltalk или о правиле Haskell/Swift, где приоритет объявляется вместе с оператором. Жёсткая таблица приоритетов на каждый символ плохо переносит расширение. В ANTLR три уровня Smalltalk записываются тремя правилами (`keywordExpr : binaryExpr (KEYWORD binaryExpr)*` и так далее), а селектор ключевого сообщения собирается конкатенацией токенов `KEYWORD` в семантическом действии или визиторе.

**Посылку сообщения можно компилировать по-разному.** В статически типизированном языке класс получателя известен с точностью до иерархии, и вызов компилируется в косвенный переход через таблицу виртуальных методов (vtable): номер слота известен при компиляции, стоимость — две загрузки и переход. При утиной типизации слота нет: нужен поиск по селектору в словаре методов класса (Blue Book, гл. 27–28), и его ускоряют глобальный кэш, встроенный кэш в месте вызова и PIC. Если вы генерируете код для JVM, есть готовый механизм: `invokedynamic` с call site, который перепривязывается во время выполнения, по сути — встроенный кэш, предоставленный платформой. В CPython-байткоде и WASM поиск по имени придётся писать самим — начните с глобального кэша `(класс, селектор) → метод` и инвалидации при изменении класса.

**Управляющие конструкции можно вынести в библиотеку**, если в языке есть дешёвые замыкания и нелокальный возврат. Тогда в ядре остаются посылка сообщения, блок и возврат, а `if`, `while`, `for`, `try` — методы. Но будьте готовы сделать то же, что Smalltalk: распознать в компиляторе типовые формы (`ifTrue:ifFalse:` с литеральными блоками) и сгенерировать условные переходы, иначе каждое условие будет стоить создания двух замыканий и динамического вызова. Это классическая оптимизация на уровне [промежуточного кода](../lectures/html/10-generaciya-promezhutochnogo-koda.html), и о ней нужно честно сказать в описании языка, раз она меняет семантику переопределения.

**Решите, что делать с непонятым сообщением.** Ошибка компиляции (Java), исключение (Python `AttributeError`) или перехватываемое сообщение (`doesNotUnderstand:`, `method_missing`) — три разные семантики с разной ценой для статического анализа. Перехват даёт прокси, ленивую загрузку и DSL, но делает невозможной проверку «такой метод существует» до выполнения.

## Упражнение

1. Предскажите результат по правилам Smalltalk, затем проверьте вычислителем `binary_ltr.py`: `2 + 3 factorial * 2`, `10 - 2 - 3`, `2 raisedTo: 3 + 1 max: 5`. Для последнего объясните, почему вычислитель падает (или должен падать), и какое сообщение получил бы Smalltalk.

    ??? question "Ответ"
        `2 + 3 factorial * 2` → унарное первым: `3 factorial = 6`, затем слева направо `2 + 6 = 8`, `8 * 2 = 16`. `10 - 2 - 3` → `5` (как и в Python: вычитание левоассоциативно). В третьем выражении ключевые слова `raisedTo:` и `max:` образуют **один** селектор `raisedTo:max:`, которого у чисел нет; наш вычислитель падает с `KeyError`, а в Smalltalk получатель `2` получил бы `doesNotUnderstand:` с сообщением `raisedTo:max:` (аргументы `4` и `5`). Нужны скобки: `(2 raisedTo: 3 + 1) max: 5` → `16`.

2. Расширьте `if_as_message.py`: добавьте `or_`, `if_false_if_true` и класс `Nil_` с методом `if_nil(block)`, а у обычных объектов — `if_nil`, возвращающий `self`. Затем добавьте в `binary_ltr.py` каскад `;`: `3 + 1; * 10` должно вернуть результат последнего сообщения (`30`), посланного тому же получателю `3`, что и первое.

## Источники

- A. Kay. The Early History of Smalltalk. HOPL II, 1993 — [hopl-smalltalk](../languages/sources.md#hopl-smalltalk); доступный текст: <https://worrydream.com/EarlyHistoryOfSmalltalk/>. Цитаты о шести идеях, «thousands of computers» и восстанавливаемом образе — оттуда.
- D. Ingalls. The Evolution of Smalltalk: from Smalltalk-72 through Squeak. HOPL IV, 2020 — [hopl-smalltalk-squeak](../languages/sources.md#hopl-smalltalk-squeak).
- A. Goldberg, D. Robson. Smalltalk-80: The Language and its Implementation. Addison-Wesley, 1983 — [smalltalk-80-blue-book](../languages/sources.md#smalltalk-80-blue-book); [PDF](http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf). Гл. 2 (синтаксис и правила разбора), 4 (поиск метода и `doesNotUnderstand:`), 5 (метаклассы), 14 (`True`/`False`), 26 (переходы вместо посылки условных сообщений), 28 (кэш методов).
- Pharo by Example 9 — главы [Syntax in a nutshell](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/SyntaxNutshell/SyntaxNutshell.md), [Understanding message syntax](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/UnderstandingMessage/UnderstandingMessage.md), [The Pharo object model](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/PharoObjectModel/PharoObjectModel.md), [Classes and metaclasses](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Metaclasses/Metaclasses.md), [Reflection](https://github.com/SquareBracketAssociates/PharoByExample9/blob/master/Chapters/Reflection/Reflection.md); все книги — <https://books.pharo.org/>.
- L. P. Deutsch, A. M. Schiffman. Efficient implementation of the Smalltalk-80 system. POPL 1984. [doi:10.1145/800017.800542](https://doi.org/10.1145/800017.800542).
- U. Hölzle, C. Chambers, D. Ungar. Optimizing Dynamically-Typed Object-Oriented Languages with Polymorphic Inline Caches. ECOOP 1991. <https://bibliography.selflanguage.org/pics.html>.
- Python Data Model: [`__getattr__`](https://docs.python.org/3/reference/datamodel.html#object.__getattr__), [Special method lookup](https://docs.python.org/3/reference/datamodel.html#special-method-lookup); MDN: [Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy).
- Карточки каталога: [Smalltalk](../languages/smalltalk.md), [Python](../languages/python.md), [JavaScript](../languages/javascript.md), [Erlang](../languages/erlang.md), [Java](../languages/java.md).
