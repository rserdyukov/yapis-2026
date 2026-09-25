---
publish: true
layout: landing
---

# Учебный курс

От примеров программ — к грамматике, анализаторам и генерации кода.
Курс состоит из пяти крупных тем. К каждой теме привязаны слайды лекций,
лабораторные работы, практические занятия, тесты, книги и статьи.

<div class="grid cards" markdown>

- **[Лекции](../lectures/index.md)**

    Все слайды курса в браузере, от введения до графовых грамматик.

- **[Лабораторный практикум](../labs/index.md)**

    Пять работ, общие требования к языку, варианты заданий и структура отчёта.

- **[Практические занятия](../practice/index.md)**

    Пять задач с теорией, вариантами и разобранными примерами:
    от конечного автомата до промежуточного кода.

- **[Тесты](../tests/index.md)**

    Тесты для самопроверки по темам курса. Раздел наполняется.

</div>

## Темы курса

### 1. Язык и языковой процессор { #tema-1 }

Что такое формальный язык и язык программирования, как устроен языковой процессор,
с чего начинается проектирование собственного языка.

<div class="course-topic-links" markdown>

- **Слайды:** [00. Введение](../lectures/html/00-vvedenie.html) ·
  [01. Понятие языкового процессора](../lectures/html/01-ponyatie-yazykovogo-processora.html) ·
  [02. Понятие языка](../lectures/html/02-ponyatie-yazyka.html) ·
  [03. Проектирование процедурного языка](../lectures/html/03-proektirovanie-procedurnogo-yazyka-programmirovaniya.html)
- **Лабораторная работа:** [ЛР 1 — примеры программ и описание варианта](../labs/index.md#lab-1) ·
  [варианты заданий](../labs/index.md#varianty) ·
  [требования к языку](../labs/index.md#trebovaniya)
- **Практика и тесты:** [практическое занятие](../practice/index.md#tema-1) · [тест](../tests/index.md#tema-1) — в плане
- **Книги и статьи:** [Орлов, «Теория и практика языков программирования»](../languages/sources.md#orlov-2013) ·
  [Непейвода, «Стили и методы программирования»](../languages/sources.md#nepeivoda) ·
  [Хомский, «Three Models for the Description of Language»](../languages/sources.md#chomsky-1956)
- **Понятия онтологии:** [связывание](../languages/glossary.md#bindings) ·
  [парадигмы](../languages/glossary.md#paradigm-supported) ·
  [соответствия практикуму](../languages/lab-mapping.md)

</div>

### 2. Лексика и синтаксис { #tema-2 }

Регулярные и контекстно-свободные грамматики, синтаксический анализ,
построение анализатора с помощью ANTLR.

<div class="course-topic-links" markdown>

- **Слайды:** [04. Регулярные грамматики](../lectures/html/04-regulyarnye-grammatiki.html) ·
  [05. Контекстно-свободные грамматики](../lectures/html/05-kontekstno-svobodnye-grammatiki.html) ·
  [06. Построение синтаксического анализатора](../lectures/html/06-postroenie-sintaksicheskogo-analizatora.html) ·
  [09. Построение компилятора с помощью ANTLR](../lectures/html/09-postroenie-kompilyatora-s-pomoschyu-antlr.html)
- **Лабораторные работы:** [ЛР 2 — ANTLR-грамматика](../labs/index.md#lab-2) ·
  [ЛР 3 — синтаксический анализатор](../labs/index.md#lab-3)
- **Практические занятия:** [задача 1 — конечный автомат](../practice/task1.md) ·
  [задача 2 — КС-грамматика](../practice/task2.md) ·
  [задача 3 — предиктивный анализатор](../practice/task3.md) ·
  [задача 4 — SLR-анализатор](../practice/task4.md)
- **Тесты:** [по теме](../tests/index.md#tema-2) — в плане
- **Книги и статьи:** [Ахо, Сети, Ульман, «Компиляторы»](../languages/sources.md#aho-sethi-ullman) ·
  [Парр, «The Definitive ANTLR 4 Reference»](../languages/sources.md#antlr-reference) ·
  [Кнут, «On the Translation of Languages from Left to Right»](../languages/sources.md#knuth-lr) ·
  [ANTLR и grammars-v4](../languages/sources.md#antlr)
- **Понятия онтологии:** [синтаксис](../languages/glossary.md#syntax)

</div>

### 3. Семантика и ошибки { #tema-3 }

Виды семантики, атрибутные грамматики, семантические проверки,
классы ошибок и стратегии восстановления.

<div class="course-topic-links" markdown>

- **Слайды:** [07. Семантический анализатор](../lectures/html/07-semanticheskiy-analizator.html) ·
  [08. Обработка ошибок](../lectures/html/08-obrabotka-oshibok.html)
- **Лабораторная работа:** [ЛР 4 — семантические проверки](../labs/index.md#lab-4)
- **Практика и тесты:** [практическое занятие](../practice/index.md#tema-3) · [тест](../tests/index.md#tema-3) — в плане
- **Книги и статьи:** [Ахо, Сети, Ульман, «Компиляторы»](../languages/sources.md#aho-sethi-ullman) ·
  [Кнут, «Semantics of Context-Free Languages»](../languages/sources.md#knuth-attributes) ·
  [Crafting Interpreters](../languages/sources.md#crafting-interpreters)
- **Понятия онтологии:** [области видимости](../languages/glossary.md#scope) ·
  [типы](../languages/glossary.md#typing) ·
  [подпрограммы](../languages/glossary.md#subprograms) ·
  [ошибки](../languages/glossary.md#errors)

</div>

### 4. Трансляция и генерация кода { #tema-4 }

Промежуточное представление, оптимизация, синтаксически управляемая трансляция
и генерация кода для виртуальной машины.

<div class="course-topic-links" markdown>

- **Слайды:** [10. Генерация промежуточного кода](../lectures/html/10-generaciya-promezhutochnogo-koda.html) ·
  [11. Оптимизация кода](../lectures/html/11-optimizaciya-koda.html) ·
  [12. Синтаксически управляемая трансляция](../lectures/html/12-sintaksicheski-upravlyaemaya-translyaciya.html)
- **Лабораторная работа:** [ЛР 5 — генерация целевого кода и отчёт](../labs/index.md#lab-5) ·
  [HOWTO: генерация целевого кода](../labs/codegen-howto.md) ·
  [решения прошлого года](../labs/past-works.md) ·
  [структура отчёта](../labs/index.md#otchet)
- **Практические занятия:** [задача 5 — синтаксически управляемая трансляция](../practice/task5.md)
- **Тесты:** [по теме](../tests/index.md#tema-4) — в плане
- **Книги и статьи:** [Ахо, Сети, Ульман, «Компиляторы»](../languages/sources.md#aho-sethi-ullman) ·
  [документация целевых платформ](../languages/sources.md#jvm-spec) ·
  [Compiler Explorer](../languages/sources.md#godbolt)
- **Понятия онтологии:** [вычисление](../languages/glossary.md#evaluation) ·
  [память](../languages/glossary.md#memory)

</div>

### 5. Оценка и развитие языков { #tema-5 }

Критерии оценки языков, графовые грамматики и направления развития языковых процессоров.

<div class="course-topic-links" markdown>

- **Слайды:** [20. Критерии оценки языков программирования](../lectures/html/20-kriterii-ocenki-yazykov-programmirovaniya.html) ·
  [30. Графовые грамматики](../lectures/html/30-grafovye-grammatiki.html) ·
  [40. Текущие направления развития языковых процессоров](../lectures/html/40-tekuschie-napravleniya-razvitiya-yazykovyh-processorov.html)
- **Практика и тесты:** [практическое занятие](../practice/index.md#tema-5) · [тест](../tests/index.md#tema-5) — в плане
- **Книги и статьи:** [Себеста, «Основные концепции языков программирования»](../languages/sources.md#sebesta) ·
  [Страуструп, «Дизайн и эволюция C++»](../languages/sources.md#stroustrup-de) ·
  [Бэкус, «Can Programming Be Liberated from the von Neumann Style?»](../languages/sources.md#backus-1978)
- **Исследовать:** [каталог языков](../languages/index.md) ·
  [сравнение языков](../languages/concepts.md) ·
  [различающие примеры](../concepts/examples/index.md)

</div>
