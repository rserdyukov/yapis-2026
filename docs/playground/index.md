---
publish: true
title: Playground компилятора FSM
search:
  exclude: true
---

# Playground: компилятор FSM → WebAssembly

Учебный компилятор языка конечных автоматов (карточка задачи «Диалог
банкомата») работает прямо в браузере. Код компилятора на Python тот же, что в
[`examples/atm-lang`](https://github.com/rserdyukov/yapis-2026/tree/main/examples/atm-lang),
его исполняет [Pyodide](https://pyodide.org/). Компилятор выдаёт WAT и
двоичный `.wasm`, а браузер исполняет модуль через `WebAssembly.instantiate`.
Сервера нет, всё выполняется на вашей машине.

<div class="fsm-pg" id="fsm-playground" markdown="0">
  <div class="fsm-pg__bar">
    <label>Пример
      <select id="pg-example" aria-label="Пример программы"></select>
    </label>
    <label>Фронтенд
      <select id="pg-frontend" aria-label="Парсер">
        <option value="antlr">ANTLR 4 (Visitor)</option>
        <option value="lark">Lark (LALR, Transformer)</option>
      </select>
    </label>
    <button id="pg-compile" type="button" disabled>Компилировать <kbd>Ctrl+Enter</kbd></button>
    <a id="pg-download" class="fsm-pg__link" hidden>скачать .wasm</a>
    <span id="pg-status" class="fsm-pg__status" role="status">Загрузка Python…</span>
  </div>

  <div class="fsm-pg__cols">
    <div class="fsm-pg__pane">
      <div class="fsm-pg__head">Программа <span class="fsm-pg__hint">.fsm</span></div>
      <textarea id="pg-source" spellcheck="false" aria-label="Исходный код"></textarea>
    </div>

    <div class="fsm-pg__pane">
      <div class="fsm-pg__tabs" role="tablist">
        <button role="tab" data-tab="diag" aria-selected="true">Диагностика</button>
        <button role="tab" data-tab="diagram">Диаграмма</button>
        <button role="tab" data-tab="wat">WAT</button>
        <button role="tab" data-tab="ast">AST</button>
        <button role="tab" data-tab="run">Запуск</button>
      </div>
      <div class="fsm-pg__tab" data-panel="diag"><ul id="pg-diags" class="fsm-pg__diags"></ul></div>
      <div class="fsm-pg__tab" data-panel="diagram" hidden><div id="pg-diagram" class="fsm-pg__diagram"></div></div>
      <div class="fsm-pg__tab" data-panel="wat" hidden><pre id="pg-wat" class="fsm-pg__code"></pre></div>
      <div class="fsm-pg__tab" data-panel="ast" hidden><pre id="pg-ast" class="fsm-pg__code"></pre></div>
      <div class="fsm-pg__tab" data-panel="run" hidden>
        <div class="fsm-pg__machine">
          <div>Состояние: <b id="pg-state">—</b></div>
          <div id="pg-context" class="fsm-pg__ctx"></div>
        </div>
        <div id="pg-buttons" class="fsm-pg__buttons"></div>
        <div class="fsm-pg__scenario">
          <label>Сценарий
            <select id="pg-scenario" aria-label="Сценарий событий"></select>
          </label>
          <button id="pg-run" type="button">Выполнить</button>
          <button id="pg-reset" type="button">Сброс</button>
        </div>
        <textarea id="pg-events" class="fsm-pg__events" spellcheck="false"
                  aria-label="Сценарий: событие и аргументы на строку"></textarea>
        <pre id="pg-log" class="fsm-pg__log" aria-live="polite"></pre>
      </div>
    </div>
  </div>
</div>

<noscript>Для playground нужен JavaScript и WebAssembly.</noscript>

<link rel="stylesheet" href="playground.css">
<script type="module" src="playground.js"></script>

## Как это устроено

```text
исходник ──► ANTLR или Lark ──► AST ──► семантика ──► генератор ──► WAT + .wasm ──► WebAssembly
             (fsmc/frontend_*)          (semantic.py)  (codegen.py)   (wasm.py)        (fsm-host.mjs)
```

- **Два фронтенда, один язык.** Грамматика записана дважды:
  [`Fsm.g4`](https://github.com/rserdyukov/yapis-2026/blob/main/examples/atm-lang/grammar/Fsm.g4)
  для ANTLR и
  [`fsm.lark`](https://github.com/rserdyukov/yapis-2026/blob/main/examples/atm-lang/fsmc/frontend_lark/fsm.lark)
  для Lark. Оба фронтенда строят одно и то же AST, и это проверяют тесты.
  Переключите фронтенд и сравните сообщения о синтаксических ошибках на
  `neg_13_syntax`.
- **Семантика доказывает свойства автомата.** Проверяются достижимость каждого
  состояния, путь из каждого состояния в терминальное, детерминизм и
  обработка каждого события. Все проверки идут обходом графа переходов.
  Откройте `neg_10_naive`: это перевод `naive.py` из карточки, и компилятор
  отвергает его до запуска.
- **Целевой код генерируется без сторонних инструментов.** Инструкции выбирает
  компилятор. Свой кодировщик печатает их в WAT и в двоичный формат. На
  событие приходится одна функция, ветку по текущему состоянию выбирает
  `br_table`.
- **Хост на JS только печатает.** Автомат, guard'ы и контекст живут в модуле
  WebAssembly, а JS передаёт события и выводит строки.

Первая загрузка скачивает Pyodide с CDN, около 10 МБ. Дальше браузер берёт
его из кэша.
