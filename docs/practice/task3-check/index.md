---
publish: true
title: "Самопроверка: задача 3 (LL(1))"
search:
  exclude: true
---

# Самопроверка задачи 3: FIRST, FOLLOW, таблица LL(1), трассы

Запишите решение [задачи 3](../task3.md) на языке ответа ниже и нажмите
«Проверить». Страница вычисляет правильные FIRST, FOLLOW, таблицу и трассы
**из вашей грамматики** и сравнивает их с тем, что вы записали. Ответ никуда не
отправляется: проверка идёт в браузере, результат ни на что не влияет.

Подсказки открываются по шагам: сначала — сколько ошибок, потом — где, потом —
почему. Эталон элемента можно раскрыть отдельно.

Грамматику и трассы пишите текстом. FIRST, FOLLOW и таблицу M удобнее заполнять
на вкладке **«Таблицы»**: строки и столбцы строятся по вашей грамматике, а всё
отмеченное сразу записывается в текст ответа — это одно и то же решение в двух видах.
Соответствие грамматики **описанию языка** варианта пока не проверяется —
только то, что по вашей грамматике всё построено верно.

<div class="gl" id="grammar-lab" markdown="0">
  <div class="gl__bar">
    <label>Пример
      <select id="gl-example" aria-label="Загрузить пример ответа">
        <option value="">— свой ответ —</option>
      </select>
    </label>
    <button id="gl-check" type="button" disabled>Проверить <kbd>Ctrl+Enter</kbd></button>
    <span id="gl-status" class="gl__status" role="status">Загрузка Python…</span>
  </div>
  <div class="gl__cols">
    <div class="gl__pane">
      <div class="gl__tabs" role="tablist" aria-label="Представление ответа">
        <button role="tab" id="gl-tab-text" data-view="text" aria-selected="true" aria-controls="gl-view-text">Текст</button>
        <button role="tab" id="gl-tab-grid" data-view="grid" aria-selected="false" aria-controls="gl-view-grid" disabled>Таблицы</button>
        <span class="gl__hint">DSL v1</span>
      </div>
      <textarea id="gl-source" spellcheck="false" aria-label="Ответ" role="tabpanel" aria-labelledby="gl-tab-text"></textarea>
      <div id="gl-grid" class="gl__grid" role="tabpanel" aria-labelledby="gl-tab-grid" hidden></div>
    </div>
    <div class="gl__pane">
      <div class="gl__head">Результат</div>
      <div id="gl-result" class="gl__result" aria-live="polite">
        <p class="gl__muted">Запишите ответ и нажмите «Проверить».</p>
      </div>
    </div>
  </div>
</div>

<noscript>Для самопроверки нужен JavaScript и WebAssembly. Без браузера ответ можно
проверить командой <code>python -m grammarlab check ответ.txt</code> в
<code>examples/grammar-lab</code>.</noscript>

<link rel="stylesheet" href="task3-check.css">
<script type="module" src="task3-check.js"></script>

## Язык ответа

Ответ делится на секции. Писать все секции не обязательно: проверяется то, что
записано. Символы разделяются **пробелами**: `N -> t i N`, а не `N -> tiN`.
Пунктуацию-терминал берите в одинарные кавычки: `';'`, `','`, `'('`, `'<>'`.
Пустая цепочка — `eps` (или `ε`), конец входа — `$`. Нетерминалы — те имена,
что стоят слева от `->`; стартовый — левая часть первого правила.

```text
grammar:
  P -> H G
  G -> B G | eps
  H -> h N
  N -> t i N | eps
  B -> b M ';'
  M -> ',' b M | eps

first:
  N = { t, eps }
  M = { ',', eps }

follow:
  N = { b, $ }
  M = { ';' }

table:
  M[N, t] = N -> t i N
  M[N, b] = N -> eps
  M[N, $] = N -> eps

trace "h t i b ;":
  P $         | h t i b ';' $ | P -> H G
  H G $       | h t i b ';' $ | H -> h N
  h N G $     | h t i b ';' $ | match h
  N G $       | t i b ';' $   | N -> t i N
  ...
  $           | $             | accept
```

- **table** — одна строка на непустую ячейку; незаписанные ячейки считаются
  пустыми. Если в ячейку попадают два правила, разделите их `;;`.
- **trace** — три колонки через `|`: стек (вершина слева), остаток входа,
  действие (`A -> α`, `match x`, `accept`, `error`). Неправильная строка
  заканчивается действием `error`. По условию нужны одна правильная и две
  неправильные строки.
- **conflicts** — только если грамматика не LL(1) и конфликт неустраним
  (висячий `else`, варианты 18, 28, 29): ячейка, строка с двумя деревьями
  разбора и выбранное правило.

```text
conflicts:
  M[X, else]: if i then if i then o else o
  choose M[X, else] = X -> else O
```

Нотация вариантов в [таблице задачи](../task3.md#varianty): `X…` — ноль или
больше повторений, `[X]` — ноль или одно.

Варианты 3, 4, 19–23 заданы картинками: записывайте свою грамматику по ним —
проверка шагов 4–6 от этого не зависит.

Первая загрузка скачивает Pyodide с CDN (около 6 МБ), дальше браузер берёт его
из кэша — тот же, что у [playground компилятора](../../playground/index.md).
Исходный код проверки: [`examples/grammar-lab`](https://github.com/rserdyukov/yapis-2026/tree/main/examples/grammar-lab).
