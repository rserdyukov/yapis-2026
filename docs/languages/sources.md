---
publish: true
---

<!-- ВНИМАНИЕ. Файл собирается автоматически: tools/build-catalog.py
     Текст и publish карточек меняйте в docs/languages/_data/.
     Метаданные служебных страниц (index, concepts, glossary, people, sources…)
     сохраняются при пересборке. -->

# Источники

Книги, статьи, конференции, сайты и инструменты, на которые опираются курс и онтология. У каждого источника указано, зачем его читать и к чему он относится: [людям](people.md), языкам, [понятиям](glossary.md), слайдам лекций и лабораторным работам.

## Книги

- <a id="orlov-2013"></a>Орлов С. А. *Теория и практика языков программирования*. СПб.: Питер, 2013. Основной учебник курса по устройству и классификации языков программирования.
    <br>Связи — лекции: [02. Понятие языка](../lectures/html/02-ponyatie-yazyka.html), [03. Проектирование процедурного языка программирования](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html), [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html).
- <a id="aho-sethi-ullman"></a>Альфред Ахо, Рави Сети, Джеффри Ульман. *Компиляторы: принципы, технологии и инструменты*. Пер. с англ. М.: Вильямс, 2001. Классический учебник по лексическому и синтаксическому анализу, промежуточному коду и оптимизации.
    <br>Связи — люди: [Альфред Ахо](people.md#aho), [Рави Сети](people.md#sethi), [Джеффри Ульман](people.md#ullman); лекции: [04. Регулярные грамматики](../lectures/html/04-regulyarnye-grammatiki.html), [05. Контекстно-свободные грамматики](../lectures/html/05-kontekstno-svobodnye-grammatiki.html), [06. Построение синтаксического анализатора](../lectures/html/06-postroenie-sintaksicheskogo-analizatora.html), [07. Семантический анализатор](../lectures/html/07-semanticheskiy-analizator.html), [10. Генерация промежуточного кода](../lectures/html/10-generaciya-promezhutochnogo-koda.html), [11. Оптимизация кода](../lectures/html/11-optimizaciya-koda.html), [12. Синтаксически управляемая трансляция](../lectures/html/12-sintaksicheski-upravlyaemaya-translyaciya.html); практикум: [ЛР 2](../labs/index.md#lab-2), [ЛР 3](../labs/index.md#lab-3), [ЛР 4](../labs/index.md#lab-4), [ЛР 5](../labs/index.md#lab-5).
- <a id="sebesta"></a>Себеста Р. У. *Основные концепции языков программирования, 5-е изд.* Пер. с англ. М.: Вильямс, 2001. Сравнение конструкций языков и критерии их оценки; основа лекции о критериях.
    <br>Связи — понятия: [Правило разрешения имён](glossary.md#scope-resolution), [Связывание параметров](glossary.md#subprograms-parameter-passing), [Проверка типов](glossary.md#typing-checking); лекции: [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html).
- <a id="stroustrup-de"></a>Бьёрн Страуструп. *Дизайн и эволюция C++*. Пер. с англ. М.: ДМК Пресс; СПб.: Питер, 2006. Как автор языка обосновывает конкретные проектные решения и компромиссы.
    <br>Связи — люди: [Бьёрн Страуструп](people.md#stroustrup); языки: [C++](cpp.md); понятия: [Освобождение ресурсов](glossary.md#resources-cleanup), [Перегрузка по сигнатуре](glossary.md#subprograms-overloading).
- <a id="nepeivoda"></a>Непейвода Н. Н. *Стили и методы программирования*. 2016. Стили и парадигмы программирования как разные способы мышления о задаче.
    <br>Связи — понятия: [Поддерживаемые парадигмы](glossary.md#paradigm-supported); лекции: [02. Понятие языка](../lectures/html/02-ponyatie-yazyka.html).
- <a id="crafting-interpreters"></a>Роберт Нистром. [Crafting Interpreters](https://craftinginterpreters.com/). 2021. Бесплатная онлайн-книга; пошаговая реализация интерпретатора и компилятора в байт-код.
    <br>Связи — люди: [Роберт Нистром](people.md#nystrom); практикум: [ЛР 3](../labs/index.md#lab-3), [ЛР 4](../labs/index.md#lab-4), [ЛР 5](../labs/index.md#lab-5).
- <a id="antlr-reference"></a>Теренс Парр. [The Definitive ANTLR 4 Reference](https://pragprog.com/titles/tpantlr2/the-definitive-antlr-4-reference/). Pragmatic Bookshelf, 2013. Справочник автора ANTLR по грамматикам, visitor/listener и обработке ошибок.
    <br>Связи — люди: [Теренс Парр](people.md#parr); лекции: [09. Построение компилятора с помощью ANTLR](../lectures/html/09-postroenie-kompilyatora-s-pomoschyu-antlr.html); практикум: [ЛР 2](../labs/index.md#lab-2), [ЛР 3](../labs/index.md#lab-3).

## Статьи

- <a id="perlis-epigrams"></a>Алан Перлис. [Epigrams on Programming](https://www.cs.yale.edu/homes/perlis-alan/quotes.html). ACM SIGPLAN Notices 17(9), 1982. DOI: [10.1145/947955.1083808](https://doi.org/10.1145/947955.1083808). Эпиграмма 19: язык, который не влияет на то, как вы думаете о программировании, не стоит изучать.
    <br>Связи — люди: [Алан Перлис](people.md#perlis).
- <a id="iverson-notation"></a>Кеннет Айверсон. *Notation as a Tool of Thought*. Communications of the ACM 23(8), 1980. DOI: [10.1145/358896.358899](https://doi.org/10.1145/358896.358899). Тьюринговская лекция о нотации как инструменте мышления; примеры на APL.
    <br>Связи — люди: [Кеннет Айверсон](people.md#iverson); понятия: [Поднятие операций по рангу массива](glossary.md#evaluation-rank-lifting).
- <a id="chomsky-1956"></a>Ноам Хомский. *Three Models for the Description of Language*. IRE Transactions on Information Theory 2(3), 1956. DOI: [10.1109/TIT.1956.1056813](https://doi.org/10.1109/TIT.1956.1056813). Исходная работа, в которой сравниваются модели грамматик — основа иерархии Хомского.
    <br>Связи — люди: [Ноам Хомский](people.md#chomsky); лекции: [02. Понятие языка](../lectures/html/02-ponyatie-yazyka.html), [04. Регулярные грамматики](../lectures/html/04-regulyarnye-grammatiki.html), [05. Контекстно-свободные грамматики](../lectures/html/05-kontekstno-svobodnye-grammatiki.html).
- <a id="knuth-lr"></a>Дональд Кнут. *On the Translation of Languages from Left to Right*. Information and Control 8(6), 1965. DOI: [10.1016/S0019-9958(65)90426-2](https://doi.org/10.1016/S0019-9958(65)90426-2). Определение LR(k)-грамматик и анализатора, лежащего в основе LR- и SLR-разбора.
    <br>Связи — люди: [Дональд Кнут](people.md#knuth); лекции: [06. Построение синтаксического анализатора](../lectures/html/06-postroenie-sintaksicheskogo-analizatora.html).
- <a id="knuth-attributes"></a>Дональд Кнут. *Semantics of Context-Free Languages*. Mathematical Systems Theory 2(2), 1968. DOI: [10.1007/BF01692511](https://doi.org/10.1007/BF01692511). Атрибутные грамматики — способ связать семантику с деревом разбора.
    <br>Связи — люди: [Дональд Кнут](people.md#knuth); лекции: [07. Семантический анализатор](../lectures/html/07-semanticheskiy-analizator.html), [12. Синтаксически управляемая трансляция](../lectures/html/12-sintaksicheski-upravlyaemaya-translyaciya.html).
- <a id="backus-1978"></a>Джон Бэкус. *Can Programming Be Liberated from the von Neumann Style?*. Communications of the ACM 21(8), 1978. DOI: [10.1145/359576.359579](https://doi.org/10.1145/359576.359579). Тьюринговская лекция с критикой языков, построенных вокруг присваивания; программа функционального стиля FP.
    <br>Связи — люди: [Джон Бэкус](people.md#backus); понятия: [Формы присваивания и связывания](glossary.md#bindings-assignment), [Контроль эффектов](glossary.md#evaluation-effects).
- <a id="wadler-blott-1989"></a>Филип Уодлер, Stephen Blott. *How to Make Ad-hoc Polymorphism Less Ad Hoc*. POPL '89, 1989. DOI: [10.1145/75277.75283](https://doi.org/10.1145/75277.75283). Статья, в которой предложены классы типов Haskell.
    <br>Связи — люди: [Филип Уодлер](people.md#wadler); языки: [Haskell](haskell.md); понятия: [Контракты полиморфизма](glossary.md#abstraction-contracts), [Перегрузка по сигнатуре](glossary.md#subprograms-overloading).
- <a id="hopl-c"></a>Деннис Ритчи. *The Development of the C Language*. HOPL II, 1993. DOI: [10.1145/154766.155580](https://doi.org/10.1145/154766.155580). История C от BCPL и B; объяснение модели указателей и массивов.
    <br>Связи — люди: [Деннис Ритчи](people.md#ritchie); языки: [C](c.md).
- <a id="hopl-cpp"></a>Бьёрн Страуструп. *A History of C++*. HOPL II, 1993. DOI: [10.1145/154766.155375](https://doi.org/10.1145/154766.155375). Происхождение классов, перегрузки и шаблонов C++.
    <br>Связи — люди: [Бьёрн Страуструп](people.md#stroustrup); языки: [C++](cpp.md).
- <a id="hopl-prolog"></a>Ален Колмероэ, Филипп Руссель. *The Birth of Prolog*. HOPL II, 1993. DOI: [10.1145/154766.155362](https://doi.org/10.1145/154766.155362). Как из задач обработки естественного языка появился Prolog.
    <br>Связи — люди: [Ален Колмероэ](people.md#colmerauer), [Филипп Руссель](people.md#roussel); языки: [Prolog](prolog.md); понятия: [Логический поиск решений](glossary.md#control-logic-search).
- <a id="hopl-lisp"></a>Гай Стил, Ричард Гэбриел. *The Evolution of Lisp*. HOPL II, 1993. DOI: [10.1145/154766.155373](https://doi.org/10.1145/154766.155373). История диалектов Lisp и их объединения в Common Lisp.
    <br>Связи — люди: [Гай Стил](people.md#steele), [Ричард Гэбриел](people.md#gabriel); языки: [Common Lisp](common-lisp.md).
- <a id="hopl-haskell"></a>Пол Худак, Джон Хьюз, Саймон Пейтон-Джонс, Филип Уодлер. *A History of Haskell — Being Lazy with Class*. HOPL III, 2007. DOI: [10.1145/1238844.1238856](https://doi.org/10.1145/1238844.1238856). Решения комитета Haskell о нестрогости, классах типов и монадическом вводе-выводе.
    <br>Связи — люди: [Пол Худак](people.md#hudak), [Джон Хьюз](people.md#hughes), [Саймон Пейтон-Джонс](people.md#peyton-jones), [Филип Уодлер](people.md#wadler); языки: [Haskell](haskell.md); понятия: [Стратегия вычисления](glossary.md#evaluation-strategy), [Контроль эффектов](glossary.md#evaluation-effects), [Контракты полиморфизма](glossary.md#abstraction-contracts).
- <a id="hopl-javascript"></a>Брендан Эйх, Allen Wirfs-Brock. *JavaScript: The First 20 Years*. Proc. ACM Program. Lang. 4, HOPL IV, 2020. DOI: [10.1145/3386327](https://doi.org/10.1145/3386327). Создание JavaScript и развитие стандарта ECMAScript.
    <br>Связи — люди: [Брендан Эйх](people.md#eich); языки: [JavaScript](javascript.md).

## Конференции

- <a id="hopl"></a>[HOPL — History of Programming Languages](https://hopl4.sigplan.org/). Конференция ACM SIGPLAN, где авторы языков описывают историю и мотивы проектных решений; проводится раз в 10–15 лет.
- <a id="popl"></a>[POPL — Principles of Programming Languages](https://www.sigplan.org/Conferences/POPL/). Ведущая конференция по теории языков программирования: семантика, типы, верификация.
- <a id="pldi"></a>[PLDI — Programming Language Design and Implementation](https://www.sigplan.org/Conferences/PLDI/). Конференция по проектированию и реализации языков, компиляторам и анализу программ.

## Сайты и каталоги

- <a id="pldb"></a>[PLDB — Programming Language DataBase](https://pldb.io/). Справочная база языков программирования; годы появления и признаки.
- <a id="hopl-info"></a>[HOPL — онлайн-энциклопедия языков программирования](https://hopl.info/). Каталог исторических языков с библиографией.
- <a id="rosetta-code"></a>[Rosetta Code](https://rosettacode.org/). Одни и те же задачи на сотнях языков — удобно сравнивать запись решений.
- <a id="godbolt"></a>[Compiler Explorer](https://godbolt.org/). Показывает, во что компилируется код на разных языках и платформах.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).

## Документация и инструменты

### ANTLR

- <a id="antlr"></a>[ANTLR — документация и загрузка](https://www.antlr.org/). Генератор лексических и синтаксических анализаторов — основной инструмент практикума.
    <br>Связи — лекции: [09. Построение компилятора с помощью ANTLR](../lectures/html/09-postroenie-kompilyatora-s-pomoschyu-antlr.html); практикум: [ЛР 2](../labs/index.md#lab-2), [ЛР 3](../labs/index.md#lab-3).
- <a id="antlr-lab"></a>[ANTLR Lab](http://lab.antlr.org/). Отладка грамматики в браузере, без установки.
    <br>Связи — практикум: [ЛР 2](../labs/index.md#lab-2).
- <a id="grammars-v4"></a>[Коллекция грамматик grammars-v4](https://github.com/antlr/grammars-v4). Справочник по стилю грамматик; не источник для копирования в лабораторную работу.
    <br>Связи — практикум: [ЛР 2](../labs/index.md#lab-2).

### Целевой код: байт-код JVM

- <a id="jvm-spec"></a>[The Java Virtual Machine Specification, Java SE 21](https://docs.oracle.com/javase/specs/jvms/se21/html/). Формат class-файла и набор инструкций JVM.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="jasmin"></a>[Jasmin](https://jasmin.sourceforge.net/). Ассемблер JVM; текст .j превращается в class-файл.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="ow2-asm"></a>[ASM](https://asm.ow2.io/). Библиотека генерации байт-кода JVM без промежуточного ассемблера.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).

### Целевой код: .NET CIL

- <a id="ecma-335"></a>[ECMA-335 Common Language Infrastructure](https://ecma-international.org/publications-and-standards/standards/ecma-335/). Стандарт CIL и формата сборок .NET; ассемблер — ilasm.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="cecil"></a>[Mono.Cecil](https://github.com/jbevain/cecil). Библиотека генерации и чтения сборок .NET.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).

### Целевой код: LLVM IR

- <a id="llvm-langref"></a>[LLVM Language Reference Manual](https://llvm.org/docs/LangRef.html). Описание LLVM IR; инструменты — llvm-as и lli.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).

### Целевой код: байт-код CPython

- <a id="python-dis"></a>[Модуль dis](https://docs.python.org/3/library/dis.html). Инструкции байт-кода CPython и дизассемблер.
    <br>Связи — языки: [Python](python.md); практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="python-bytecode"></a>[bytecode](https://pypi.org/project/bytecode/). Библиотека сборки объектов кода CPython.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).

### Целевой код: WAT / WebAssembly

- <a id="wasm-spec"></a>[WebAssembly Specification](https://webassembly.github.io/spec/core/). Спецификация WebAssembly и его текстового формата WAT.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="wabt"></a>[WABT](https://github.com/WebAssembly/wabt). wat2wasm и другие утилиты WebAssembly.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
- <a id="wasmtime"></a>[Wasmtime](https://wasmtime.dev/). Среда выполнения WebAssembly вне браузера.
    <br>Связи — практикум: [ЛР 5](../labs/index.md#lab-5).
