---
publish: true
---

# HOWTO: генерация целевого кода (ЛР 5)

Это практическое руководство к [лабораторной работе 5](index.md). В ней
компилятор, который уже умеет находить синтаксические и семантические ошибки,
должен научиться выдавать программу для виртуальной машины из вашего варианта
([раздел «Целевой код»](index.md#celevoy-kod)).

Руководство построено на разборе работ прошлого года: 22 компилятора под
все пять платформ. Работы названы по реализованному языку и платформе
(например, «MathPL → WAT»). Их запускали, а
сгенерированный код дизассемблировали. Отсюда советы «делайте так» и
предупреждения «так делали, и вот что сломалось».

!!! tip "Как читать"
    Разделы 1–4 общие для всех платформ, прочитайте их целиком.
    Затем откройте раздел своей платформы: [WAT](#wat), [JVM](#jvm),
    [CIL](#cil), [LLVM IR](#llvm), [CPython](#cpython). Раздел 10 про тесты
    и чек-лист перед сдачей.

## 1. Что считается генерацией кода

Компилятор **сам выбирает инструкции целевой машины**: стековые операции,
переходы, работу с переменными, вызовы. Ассемблер (Jasmin, ilasm, wat2wasm,
clang, библиотека `bytecode`) только переводит текст или объекты в двоичный
формат. Так и должно быть.

| Подход | Засчитывается? |
|---|---|
| Генерация текста ассемблера (`.j`, `.il`, `.wat`, `.ll`) или объектов `Instr` → ассемблер | Да, это и есть задание |
| Генерация кода через библиотеку-builder (`llvmlite.ir`, ASM для JVM) | Да, если инструкции выбираете вы |
| Генерация исходника на C / Python / C# и компиляция его чужим компилятором | **Нет**, это транспиляция |
| Построение Python-`ast` и `compile()` | Нет: выбор инструкций делает CPython |

В прошлом году были две работы второго типа. Одна генерировала C и вызывала
`clang -S -emit-llvm`. Другая склеивала Python-исходник из заглушек и вызывала
`compile()`. Ни одну из них нельзя считать генератором кода.

**Сложные операции предметной области можно (и нужно) писать на обычном языке**
в отдельной runtime-библиотеке: на Java, C#, C, JS или Python. Сгенерированный
код её вызывает. Это не транспиляция: управление потоком, выражения, переменные
и вызовы по-прежнему генерирует ваш компилятор. Подробнее в [§ 3.4](#runtime).

## 2. Архитектура генератора

### 2.1. Конвейер { #konveyer }

```text
исходник ──► лексер/парсер ──► семантический анализ ──► генератор ──► ассемблер ──► запуск
              (ЛР 3)             (ЛР 4)                  (ЛР 5)       внешний       VM
                   ошибки? стоп         ошибки? стоп
```

1. **Генератор запускается только при нуле ошибок** на всех предыдущих фазах.
   В прошлом году одна из работ запускала генератор при семантических ошибках
   и получала `VerifyError` вместо понятного сообщения.
2. **Семантика аннотирует дерево, генератор только читает аннотации.** К
   моменту генерации для каждого выражения известен тип, а для каждого имени
   известен символ: глобальный или локальный, номер слота, тип. Хранить можно
   в словаре `types[ctx]` / `symbols[ctx]`, в `ParseTreeProperty` (Java) или
   в полях собственного AST.
3. **Генератор не выводит типы заново** и не заглядывает в «текущую область
   видимости» семантического анализатора. После его прохода эта область
   указывает на глобальный уровень. Одна из работ именно так теряла все
   присваивания локальным переменным функций и лечила это `if` по имени
   конкретной функции.

Хорошие образцы разделения фаз:

- StringLang → JVM: `SemanticAnalyzer` → `CodeGenerator` → `Emitter`, типы из `type_cache`;
- GSL → LLVM: отдельный семантический visitor и visitor генерации;
- MathPL → WAT: анализатор записывает `ctx.type`, `ctx.symbol_info`, адреса строк.
  Генератор их только читает.

### 2.2. Visitor, а не Listener

Для генерации кода важен **порядок**: условие `while` должно идти перед телом,
метка `else` должна появиться между ветками. `Listener` с методами `enter/exit`
сам решает порядок обхода детей. Итоги прошлого года:

- тело `if` выводилось **до** инструкции `if`, условие `while` выводилось
  **после** тела, так что цикл превращался в do-while;
- шаг цикла `for` приходилось буферизовать отдельно;
- метки передавались через «прибитые» к узлам атрибуты
  (`ctx.isCondition = true; ctx.falseLabel = ...`).

С `Visitor` вы сами вызываете `visit(ctx.cond)`, `visit(ctx.body)` в нужном
порядке и ставите метки между вызовами. Генерируйте ANTLR-парсер с ключом
`-visitor` и используйте метки альтернатив `#label` в грамматике, тогда у
каждой операции будет отдельный метод `visitAddExpr`, `visitWhileStmt` и т.д.

### 2.3. Emitter { #emitter }

Не пишите `print` и не склеивайте одну огромную строку. Заведите маленький
класс, который накапливает код **текущей функции**:

```python
class MethodBuilder:
    """Код одной функции целевой машины."""

    def __init__(self, name):
        self.name = name
        self.code: list[str] = []
        self.locals: dict[str, tuple[int, str]] = {}   # имя -> (слот, тип)

    def emit(self, line: str):
        self.code.append("    " + line)

    def label(self, name: str):
        self.code.append(f"{name}:")

    def declare_local(self, name: str, ty: str) -> int:
        slot = len(self.locals)          # JVM: +2 для long/double!
        self.locals[name] = (slot, ty)
        return slot

    def render(self) -> str:
        # Заголовок пишется ПОСЛЕ тела: к этому моменту
        # известны все локальные переменные и глубина стека.
        ...
```

Ключевая идея (лучше всего её реализовал ImgLang → CIL):
**функция превращается в текст в самом конце**. Тогда `declare_local()` можно
вызывать в любом месте генерации тела, а список `.locals` / `.limit locals` /
`(local ...)` / `alloca` соберётся сам. Без этого приходится делать
предварительный проход «собрать все переменные», и его легко рассинхронизировать
с генерацией.

Ещё два обязательных механизма:

- **Уникальные метки** из одного счётчика: `new_label("while_end")` →
  `while_end_17`. Префикс делает ассемблер читаемым.
- **Стек циклов** `(метка_continue, метка_break)` для `break` / `continue`.

### 2.4. Каждый `visit` что-то гарантирует

Договоритесь о контракте и соблюдайте его везде:

| Узел | Контракт |
|---|---|
| Выражение | после его кода на вершине стека лежит **ровно одно** значение его типа (в LLVM: метод возвращает имя регистра `%tN`) |
| Оператор | стек после него такой же, как до него |
| Вызов-оператор `f(x);` | если `f` возвращает значение, его нужно **снять** (`pop` / `drop` / `POP_TOP`) |

Нарушение последней строки было самой частой ошибкой прошлого года. `write(x)`
в Python-байт-коде оставлял `None` на стеке, и потом `FOR_ITER` снимал его вместо
итератора: segfault. Решайте «нужен ли `pop`» **по типу выражения** из семантики,
а не по тексту последней сгенерированной инструкции.

## 3. Общие схемы трансляции

Все пять платформ, кроме LLVM, — стековые машины, поэтому схемы одинаковы с
точностью до имён инструкций. В LLVM вместо стека регистры, но схемы блоков
те же.

### 3.1. Выражения

Постфиксный обход: сначала левый операнд, потом правый, потом операция.

```text
a + b * 2   ──►   load a
                  load b
                  const 2
                  mul
                  add
```

Неявное преобразование типов (`int + float`) — это отдельная инструкция
**сразу после** операнда, который нужно преобразовать. Какой операнд и в какой
тип, знает семантика ([§ 2.1](#konveyer)), генератор только читает.

| | WAT | JVM | CIL | LLVM | CPython |
|---|---|---|---|---|---|
| int → float | `f64.convert_i32_s` | `i2d` | `conv.r8` | `sitofp` | не нужно (вызов `float`) |
| float → int | `i32.trunc_f64_s` | `d2i` | `conv.i4` | `fptosi` | вызов `int` |

**Явное приведение `(int) x` обязано генерировать код.** В трёх работах
`visitCastExpr` был пустым, и `(string) 5` падал при запуске.

### 3.2. Условный оператор

```text
    <cond>
    if_false  ELSE_n
    <then>
    goto      END_n
ELSE_n:
    <else>
END_n:
```

В условии `if` / `while` сравнение не обязательно превращать в 0/1: можно
сразу перейти на `ELSE_n` **инвертированным** условием (`n > 1` → «прыгнуть,
если `n <= 1`»). Это короче. Так сделано в примерах ниже.

### 3.3. Циклы

```text
while c { B }          until: repeat { B } until c      for i = a to b { B }
─────────────          ───────────────────────────      ───────────────────
TOP:                   TOP:                              i = a
  <c>                    <B>                             TOP:
  if_false END           <c>                               if i > b goto END
  <B>                    if_false TOP                      <B>
  goto TOP                                               CONT:
END:                                                       i = i + 1
                                                           goto TOP
                                                         END:
```

- `until` — это цикл с постусловием: тело выполняется хотя бы раз, повтор
  идёт, **пока условие ложно**. В прошлом году `until` часто забывали, хотя это
  обязательное требование.
- В `for` `continue` ведёт на `CONT`, а не на `TOP`, иначе шаг пропустится.
  Верхнюю границу вычисляйте один раз во временную переменную.
- В WAT нет `goto`, но есть `block`/`loop`/`br_if`, см. [§ 5](#wat).

### 3.4. Runtime-библиотека { #runtime }

Операции над доменными типами (вектор, множество, граф, изображение, XML-узел,
таблица) пишите **на обычном языке** в отдельной библиотеке, а из
сгенерированного кода вызывайте:

| Платформа | Runtime | Вызов |
|---|---|---|
| JVM | `LangRuntime.java` → `javac` | `invokestatic LangRuntime/add(...)` |
| CIL | `LangRuntime.cs` → `dotnet build` | `call ... [LangRuntime]LangRuntime.Rt::Add(...)` |
| LLVM | `runtime.c` | `declare ptr @set_union(ptr, ptr)`, линковка `clang prog.ll runtime.c` |
| WAT | импорты из JS-хоста **или** функции на WAT | `(import "env" "print_str" ...)` |
| CPython | `lang_runtime.py` | `IMPORT_NAME lang_runtime` внутри .pyc |

Удачные примеры прошлого года:

- StringLang → JVM, `StringLangRuntime.java`: строковые операции на 88 строках Java;
- GSL → LLVM, `runtime.c`: граф, BFS/DFS и кратчайший путь на C, в IR только `declare` и `ptr`;
- ImageLang → CIL, `Runtime.cs`: классы `SysImage`/`SysPixel`, из IL вызываются `newobj` и `callvirt`.

Чего **не** делать:

- разворачивать встроенные функции в сотни строк ассемблера внутри генератора;
- вычислять операции над данными программы **на этапе компиляции**. Одна из
  работ «выполняла» `UPDATE ... WHERE name == "Bob"` в Python-коде компилятора
  и зашивала в IR готовую таблицу строкой;
- не импортировать runtime в сам целевой файл, так что программа работает
  только из-под вашего раннера.

### 3.5. Логические операторы: короткое вычисление

`a && f()` не должен вызывать `f`, если `a` ложно. В прошлом году это
сделали 2 работы из 22 (MathPL → WAT и «Геометрия» → JVM), остальные генерировали
побитовое `and`. Схема:

```text
a && b                          a || b
──────                          ──────
  <a>                             <a>
  if_false FALSE_n                if_true TRUE_n
  <b>                             <b>
  if_false FALSE_n                if_true TRUE_n
  const 1 ; goto END_n            const 0 ; goto END_n
FALSE_n: const 0                TRUE_n: const 1
END_n:                          END_n:
```

Внутри условия `if`/`while` ещё проще: оба `if_false` ведут прямо на `ELSE_n`.

### 3.6. Переменные и области видимости

| | Глобальная | Локальная / параметр |
|---|---|---|
| WAT | `(global $g (mut i32) ...)`, `global.get/set` | `(local $x i32)`, `local.get/set` |
| JVM | `.field public static g I`, `getstatic/putstatic` | слот, `iload/istore` |
| CIL | `.field public static int32 g`, `ldsfld/stsfld` | `.locals init`, `ldloc/stloc`, `ldarg/starg` |
| LLVM | `@g = global i32 0`, `load/store ptr @g` | `alloca` в блоке `entry`, `load/store` |
| CPython | `LOAD_NAME` (модуль), `LOAD_GLOBAL/STORE_GLOBAL` (в функции) | `LOAD_FAST/STORE_FAST` |

!!! warning "Глобальные переменные — это требование задания"
    Ни одна JVM- и CIL-работа прошлого года не сделала настоящих глобальных
    переменных. Их объявляли локальными переменными `main`, и функции их не
    видели. Используйте **статические поля** (или `global`), как в таблице.

Если в языке есть блочная область видимости, `int x` во вложенном блоке — это
**другая** переменная. Дайте ей уникальное имя или отдельный слот, например
`x_1`.

### 3.7. Передача параметров

| Вариант | Как сделать |
|---|---|
| По значению | обычный параметр |
| По ссылке | передать **адрес**: CIL `int32&` + `ldloca`/`ldind`/`stind`; LLVM параметр `ptr`; JVM массив из одного элемента или holder-класс; WAT ячейка в линейной памяти; CPython объект-обёртка `Ref` с полем `value` |
| По результату | функция возвращает дополнительные значения, вызывающий код после вызова сохраняет их в переменные-аргументы. WAT поддерживает несколько `result` напрямую |

Рабочие образцы: ImgLang → CIL (`ldloca` + `stind`), язык с лямбдами → WAT
(multi-value `result` для out-параметров), VecLang → CPython (класс `Ref`). В двух работах тип параметра в сигнатуре поменяли на указатель, а тело
функции продолжало работать с ним как со значением. Пишите тест с `out`-параметром.

### 3.8. Множественное присваивание

`a, b = b, a` — сначала вычислить **все** правые части, потом выполнить все
присваивания:

```text
load b        ; стек: b
load a        ; стек: b a
store b       ; b = старое a
store a       ; a = старое b
```

На стековой машине это получается само, если сначала пройти правые части, а
потом сохранять в обратном порядке. В LLVM нужно сначала сделать все `load`,
потом все `store`. В прошлом году одна из LLVM-работ чередовала
`load`/`store` и печатала `2 2` вместо `2 1`.

### 3.9. Функции и возврат

- Функции собирайте предварительным проходом (имя → сигнатура), тогда можно
  вызывать функцию до её определения.
- Перегрузка: целевая платформа обычно не знает ваших правил, поэтому
  **декорируйте имена**: `add_int_int`, `add_set_set`. Выбор перегрузки делает
  семантика, генератор берёт имя из аннотации вызова. Никогда не выбирайте
  перегрузку по тексту аргументов (в одной работе было
  `"add_int_int" if "a,b" in txt else ...`).
- Если функция может «выпасть» из тела без `return`, допишите в конце возврат
  значения по умолчанию или ловушку (`unreachable` в WAT). Иначе верификатор
  или валидатор отвергнет код.

## 4. Сквозной пример

Одна и та же программа ниже переведена на все пять платформ. Все листинги
**проверены**: они собираются и печатают одинаковый результат.

```text
int calls = 0                      // глобальная переменная

func fact(int n) -> int {
    calls = calls + 1
    int r = 1
    while n > 1 {
        r = r * n
        n = n - 1
    }
    return r
}

int x = read()
repeat {
    write("fact = ")               // строка без перевода строки
    write(fact(x))                 // число с переводом строки
    x = x - 2
} until x < 0
write(calls)
```

При вводе `5` программа печатает:

```text
fact = 120
fact = 6
fact = 1
3
```

Каждый листинг показывает глобальную переменную, параметр, локальную
переменную, `while`, `until`, вызов функции, строковую константу, ввод и
вывод. Сравнивайте разделы: схемы из § 3 видны в каждом.

## 5. WAT (WebAssembly) { #wat }

### 5.1. Инструменты

```bash
brew install wabt node          # Linux: apt install wabt nodejs; Windows: scoop/choco или релиз wabt с GitHub
wat2wasm prog.wat -o prog.wasm  # сборка И валидация
node run.mjs prog.wasm < in.txt # запуск
wasm2wat prog.wasm              # посмотреть, что реально собралось
```

WebAssembly не умеет печатать сам: ввод и вывод — это **импортированные
функции хоста**. Один универсальный хост на JS (`run.mjs`) подходит для любого
варианта:

```js
// node run.mjs prog.wasm < input.txt
import { readFileSync } from "node:fs";

const bytes = readFileSync(process.argv[2]);
const input = readFileSync(0, "utf8").split(/\s+/).filter(Boolean);
let memory;

const cstr = (ptr) => {                  // строка в памяти, заканчивается \0
  const mem = new Uint8Array(memory.buffer);
  let end = ptr;
  while (mem[end] !== 0) end++;
  return new TextDecoder().decode(mem.subarray(ptr, end));
};

const imports = {
  env: {
    print_i32: (x) => console.log(x),
    print_f64: (x) => console.log(x),
    print_str: (p) => process.stdout.write(cstr(p)),
    read_i32: () => parseInt(input.shift() ?? "0", 10),
    read_f64: () => parseFloat(input.shift() ?? "0"),
  },
  math: { sin: Math.sin, cos: Math.cos, pow: Math.pow, log: Math.log },
};

const { instance } = await WebAssembly.instantiate(bytes, imports);
memory = instance.exports.memory;
instance.exports.main();
```

Альтернатива для тестов на Python: `pip install wasmtime`, затем
`wasmtime.Module(engine, wat_text)` принимает **текст WAT напрямую**, а
хост-функции задаются через `Linker.define_func`. Так устроены тесты работы
Lisp → WAT: они проверяют результат выполнения, а не только факт генерации.

### 5.2. Сквозной пример

```wat
(module
  (import "env" "print_i32" (func $print_i32 (param i32)))
  (import "env" "print_str" (func $print_str (param i32)))
  (import "env" "read_i32"  (func $read_i32 (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 16) "fact = \00")              ;; строковые константы
  (global $heap (mut i32) (i32.const 1024))       ;; начало кучи
  (global $calls (mut i32) (i32.const 0))

  (func $fact (param $n i32) (result i32)
    (local $r i32)
    global.get $calls
    i32.const 1
    i32.add
    global.set $calls
    i32.const 1
    local.set $r
    block $while_end_0                            ;; while n > 1
      loop $while_top_0
        local.get $n
        i32.const 1
        i32.gt_s
        i32.eqz
        br_if $while_end_0                        ;; условие ложно -> выход
        local.get $r
        local.get $n
        i32.mul
        local.set $r
        local.get $n
        i32.const 1
        i32.sub
        local.set $n
        br $while_top_0
      end
    end
    local.get $r)

  (func $main (export "main")
    (local $x i32)
    call $read_i32
    local.set $x
    loop $until_top_1                             ;; repeat ... until x < 0
      i32.const 16
      call $print_str
      local.get $x
      call $fact
      call $print_i32
      local.get $x
      i32.const 2
      i32.sub
      local.set $x
      local.get $x
      i32.const 0
      i32.lt_s
      i32.eqz
      br_if $until_top_1                          ;; условие ложно -> повтор
    end
    global.get $calls
    call $print_i32))
```

### 5.3. Правила

- **Порядок модуля:** `import` → `memory` → `data` → `global` → служебные
  функции runtime → пользовательские функции → `main` с `export`.
- **Типы:** `int`/`bool` → `i32`, `float` → **`f64`** (не `f32`: импорты
  `Math.*` из JS работают с double), строки и коллекции → `i32`-указатель в
  линейную память.
- **Все `(local ...)` объявляются в начале функции.** Используйте
  `MethodBuilder` из [§ 2.3](#emitter) или вставьте заглушку и замените её
  после генерации тела (так сделано в RivScript → WAT).
- **Циклы — через `block`+`loop`.** `br_if $end` выходит из блока, `br $top`
  возвращает к началу цикла. `until` — это `loop` с `br_if $top` при ложном
  условии, без внешнего `block`.
- **Короткое `&&`:** `(if (result i32) (then <b>) (else i32.const 0))`.
- **Строки:** data-сегмент с `\00` в конце. Смещение считайте **в байтах
  UTF-8** (`len(s.encode("utf-8")) + 1`), а не в символах, иначе кириллица
  сдвинет все следующие строки. Смещения назначает **один** компонент.
- **Память:** bump-аллокатор на WAT (`$heap` + `$alloc(size)` с выравниванием
  до 8), коллекция в формате `[len][cap][data...]`. Образец — `wat_generator.py`
  в MathPL → WAT.
  Проверку границ делайте через `unreachable`.
- **Временные переменные — отдельные для каждого узла** (`$t0`, `$t1`, ... из
  счётчика). В лучшей работе прошлого года `a[b[0]]` возвращал 1 вместо 30:
  внутренний индекс затирал общий `$ptr_tmp` внешнего.
- **Не размещайте переменные по фиксированным адресам памяти:** при
  рекурсии все вызовы будут делить одни ячейки. Скаляры держите в `local`.
- **Функция с `(result ...)`** после тела должна оставить значение или
  выполнить `unreachable`, иначе `wat2wasm` откажет.
- Нет инструкции `f32.rem`/`f64.rem`, `if` без `then` недопустим.
  `wat2wasm` в тестах ловит это сразу.

## 6. JVM (Jasmin) { #jvm }

### 6.1. Инструменты

```bash
# JDK 17+ и jasmin.jar (Jasmin 2.4, jasmin.sourceforge.net)
java -jar jasmin.jar -d out Main.j        # .j -> out/Main.class
javac -d out LangRuntime.java             # runtime
java -cp out Main < in.txt                # запуск
javap -c -v -cp out Main                  # дизассемблер для отладки
```

Jasmin выпускает class-файлы версии **45.3**. Для них JVM применяет старый
верификатор, который выводит типы сам, поэтому **StackMapTable генерировать не
нужно**. Если вместо Jasmin вы берёте библиотеку ASM, используйте
`new ClassWriter(ClassWriter.COMPUTE_FRAMES | ClassWriter.COMPUTE_MAXS)`.

!!! warning "Не называйте runtime-класс `Runtime`"
    Сгенерированный класс без пакета ссылается на `Runtime/...`, и JVM может
    найти `java.lang.Runtime`. Возьмите уникальное имя, например `LangRuntime`.

### 6.2. Сквозной пример

```jasmin
.class public Main
.super java/lang/Object

.field public static calls I                    ; глобальная переменная

.method public static fact(I)I                  ; int fact(int n)
    .limit stack 4
    .limit locals 2                             ; слот 0 = n, слот 1 = r
    getstatic Main/calls I
    iconst_1
    iadd
    putstatic Main/calls I
    iconst_1
    istore_1                                    ; r = 1
while_top_0:
    iload_0
    iconst_1
    if_icmple while_end_0                       ; выход, если n <= 1
    iload_1
    iload_0
    imul
    istore_1
    iinc 0 -1                                   ; n = n - 1
    goto while_top_0
while_end_0:
    iload_1
    ireturn
.end method

.method public static main([Ljava/lang/String;)V
    .limit stack 4
    .limit locals 2                             ; слот 0 = args, слот 1 = x
    invokestatic LangRuntime/readInt()I
    istore_1
until_top_1:
    ldc "fact = "
    invokestatic LangRuntime/writeStr(Ljava/lang/String;)V
    iload_1
    invokestatic Main/fact(I)I
    invokestatic LangRuntime/writeInt(I)V
    iinc 1 -2
    iload_1
    ifge until_top_1                            ; повтор, пока x >= 0
    getstatic Main/calls I
    invokestatic LangRuntime/writeInt(I)V
    return
.end method
```

```java
// LangRuntime.java
import java.util.Scanner;

public final class LangRuntime {
    private static final Scanner in = new Scanner(System.in);
    public static int readInt() { return in.nextInt(); }
    public static void writeInt(int x) { System.out.println(x); }
    public static void writeStr(String s) { System.out.print(s); }
}
```

### 6.3. Правила

- **Дескрипторы:** `I` int, `D` double, `Z` boolean, `C` char,
  `Ljava/lang/String;`, `[I` массив. Держите таблицу «тип языка → дескриптор»
  в одном месте (как `constants.py` в StringLang → JVM).
- **Слоты:** в `main` слот 0 занят `args`. В статической функции параметры
  занимают слоты с 0. **`long` и `double` занимают два слота.**
- **`.limit stack`:** константа допустима, но **не маленькая**. С
  `.limit stack 10` выражение из 12 вложенных скобок даёт
  `VerifyError: Stack size too large`. Лучше считать глубину в `emit()`:
  `+1` для загрузки, `-1` для бинарной операции, по сигнатуре для
  `invokestatic`.
- **Сравнения:** `int` — `if_icmpXX`; `double` — `dcmpg` + `ifXX`; `long` —
  `lcmp` + `ifXX`; строки — `String.equals` / `compareTo`.
- **Вывод:** значение уже на стеке → `getstatic java/lang/System/out Ljava/io/PrintStream;`
  → `swap` → `invokevirtual java/io/PrintStream/println(I)V`. Дескриптор
  `println` выбирается по типу выражения. Проще вызвать свой `LangRuntime.writeInt`.
- **Приведения:** `i2d`, `d2i`, `String.valueOf(I)`, `Integer.parseInt`.
- **Функции:** `public static` методы класса `Main`, вызов
  `invokestatic Main/f(desc)`.
- **Доменные типы** — Java-классы в runtime. Удачный образец, где вместо
  runtime генерируются классы `Point`, `Line`, `Circle` на Jasmin с полями
  и конструкторами: «Геометрия» → JVM. В этой же работе есть правильное короткое вычисление `&&`/`||`.

## 7. CIL (.NET) { #cil }

### 7.1. Инструменты (одинаково на Windows, Linux, macOS)

Нужен .NET SDK 8 и `ilasm` из NuGet-пакета. Путь к ilasm от .NET Framework
(`C:\Windows\Microsoft.NET\Framework64\...`) работает только на Windows:
в прошлом году из-за этого ни одна CIL-работа не собиралась на другой ОС.

```bash
# 1. Один раз: скачать ilasm (замените osx-arm64 на win-x64 / linux-x64 / osx-x64)
mkdir -p tools/ilasm && cd tools/ilasm
cat > ilasm.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <RuntimeIdentifier>osx-arm64</RuntimeIdentifier>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NETCore.ILAsm" Version="8.0.0" />
  </ItemGroup>
</Project>
EOF
dotnet restore
cd ../..
ILASM=~/.nuget/packages/runtime.osx-arm64.microsoft.netcore.ilasm/8.0.0/runtimes/osx-arm64/native/ilasm

# 2. Runtime-библиотека
dotnet build LangRuntime -c Release -o out

# 3. IL -> сборка
$ILASM -dll -output=out/prog.dll out/prog.il

# 4. Файл конфигурации рядом со сборкой (его пишет ваш компилятор)
cat > out/prog.runtimeconfig.json <<'EOF'
{ "runtimeOptions": { "tfm": "net8.0",
  "framework": { "name": "Microsoft.NETCore.App", "version": "8.0.0" } } }
EOF

# 5. Запуск
dotnet out/prog.dll < in.txt
```

`LangRuntime.dll` должна лежать рядом с `prog.dll`. Для отладки напишите тот же
фрагмент на C#, соберите и посмотрите IL через `ildasm` (NuGet
`Microsoft.NETCore.ILDAsm`) или ILSpy: так быстро находится правильный синтаксис
сигнатур и generic-вызовов.

### 7.2. Сквозной пример

```text
.assembly extern System.Runtime { .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A) .ver 8:0:0:0 }
.assembly extern LangRuntime {}
.assembly prog {}
.module prog.dll

.class public abstract sealed auto ansi Program extends [System.Runtime]System.Object
{
  .field public static int32 calls                // глобальная переменная

  .method public static int32 fact(int32 n) cil managed
  {
    .maxstack 8
    .locals init (int32 r)
    ldsfld int32 Program::calls
    ldc.i4.1
    add
    stsfld int32 Program::calls
    ldc.i4.1
    stloc r
  WHILE_TOP_0:
    ldarg n
    ldc.i4.1
    ble WHILE_END_0                               // выход, если n <= 1
    ldloc r
    ldarg n
    mul
    stloc r
    ldarg n
    ldc.i4.1
    sub
    starg n
    br WHILE_TOP_0
  WHILE_END_0:
    ldloc r
    ret
  }

  .method public static void Main() cil managed
  {
    .entrypoint
    .maxstack 8
    .locals init (int32 x)
    call int32 [LangRuntime]LangRuntime.Rt::ReadInt()
    stloc x
  UNTIL_TOP_1:
    ldstr "fact = "
    call void [LangRuntime]LangRuntime.Rt::WriteStr(string)
    ldloc x
    call int32 Program::fact(int32)
    call void [LangRuntime]LangRuntime.Rt::WriteInt(int32)
    ldloc x
    ldc.i4.2
    sub
    stloc x
    ldloc x
    ldc.i4.0
    bge UNTIL_TOP_1                               // повтор, пока x >= 0
    ldsfld int32 Program::calls
    call void [LangRuntime]LangRuntime.Rt::WriteInt(int32)
    ret
  }
}
```

```csharp
// LangRuntime/Rt.cs  (проект: dotnet new classlib -o LangRuntime -f net8.0)
using System;
using System.Globalization;

namespace LangRuntime;

public static class Rt
{
    public static int ReadInt() =>
        int.Parse(Console.ReadLine() ?? "0", CultureInfo.InvariantCulture);
    public static void WriteInt(int x) => Console.WriteLine(x);
    public static void WriteStr(string s) => Console.Write(s);
}
```

!!! note "`mscorlib` или `System.Runtime`"
    Вместо `System.Runtime` можно писать `.assembly extern mscorlib {}` и
    `[mscorlib]System.Object`. В .NET 8 есть фасад `mscorlib`, поэтому тот же IL
    работает и на .NET Framework, и на .NET 8 (проверено).

### 7.3. Правила

- **Используйте нативные типы CLR:** `int32`, `float64`, `bool`, `string`.
  «Всё как `object` + `box`» работает, но каждая операция превращается в
  `unbox.any … box`, а ошибки типов вылезают только при запуске.
- **Глобальные** — `.field static`, `ldsfld`/`stsfld` (см. пример).
- **Сравнения:** `ceq`, `clt`, `cgt`. Для `!=`, `<=`, `>=` добавьте
  `ldc.i4.0; ceq`. В условиях удобнее переходы `beq/bne.un/blt/ble/bgt/bge`.
- **`.maxstack`:** константа 8–64. По умолчанию, если директиву не написать,
  используется 8, а на длинных выражениях этого мало.
- **Вещественные литералы** пишите с `CultureInfo.InvariantCulture`
  (`ldc.r8 3.14`, а не `3,14` на русской локали). Экранируйте `"` и `\` в
  `ldstr`.
- **По ссылке:** тип параметра `int32&`. В точке вызова `ldloca x` / `ldarga`
  / `ldsflda`, внутри функции чтение `ldarg p; ldind.i4`, запись
  `ldarg p; <значение>; stind.i4`.
- **Методы значимых типов** (`valuetype`) вызываются по адресу: `stloc tmp;
  ldloca tmp; call instance ...`.
- Образцы: ImgLang → CIL (слои emitter / типы / runtime, статическая
  типизация, `ref`-параметры), SetLang (C#) → CIL (AST, хелперы `EmitLdInt`,
  цикл `foreach` через `IEnumerator`), SetLang (Java) → CIL (`switch` через
  `dup`/`pop` со сбалансированным стеком, вызов generic-метода
  `HashSet<object>::Add(!0)`).
- **Не используйте `System.Drawing`**: на .NET 6+ он работает только на Windows.
  Для изображений возьмите кроссплатформенную библиотеку, например ImageSharp,
  или свою простую реализацию.

## 8. LLVM IR { #llvm }

### 8.1. Инструменты

```bash
# macOS: системный clang есть, но lli/opt нет -> brew install llvm
# Linux: apt install clang llvm
# Windows: MSYS2 CLANG64 (pacman -S mingw-w64-clang-x86_64-clang mingw-w64-clang-x86_64-llvm) или WSL
clang -Wno-override-module prog.ll runtime.c -o prog   # самый надёжный путь
./prog < in.txt
opt -passes=verify -disable-output prog.ll              # проверить IR
lli prog.ll                                             # интерпретировать без runtime.c
opt -S -passes=mem2reg prog.ll -o prog.ssa.ll           # посмотреть «настоящий» SSA
clang -S -emit-llvm -O0 example.c -o example.ll         # как это сделал бы clang
```

Последняя команда — лучший справочник: напишите на C то, что хотите
сгенерировать, и посмотрите IR. Но **сдавать нужно IR, сгенерированный вашим
компилятором**, а не выход clang.

### 8.2. Сквозной пример

```llvm
@calls = global i32 0
@.str.0 = private unnamed_addr constant [8 x i8] c"fact = \00"
@.fmt.int = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.fmt.read = private unnamed_addr constant [3 x i8] c"%d\00"

declare i32 @printf(ptr, ...)
declare i32 @scanf(ptr, ...)

define i32 @fact(i32 %n.arg) {
entry:
  %n = alloca i32                                ; все alloca — в entry
  %r = alloca i32
  store i32 %n.arg, ptr %n                       ; параметр -> изменяемая ячейка
  %t0 = load i32, ptr @calls
  %t1 = add i32 %t0, 1
  store i32 %t1, ptr @calls
  store i32 1, ptr %r
  br label %while.cond.0
while.cond.0:
  %t2 = load i32, ptr %n
  %t3 = icmp sgt i32 %t2, 1
  br i1 %t3, label %while.body.0, label %while.end.0
while.body.0:
  %t4 = load i32, ptr %r
  %t5 = load i32, ptr %n
  %t6 = mul i32 %t4, %t5
  store i32 %t6, ptr %r
  %t7 = load i32, ptr %n
  %t8 = sub i32 %t7, 1
  store i32 %t8, ptr %n
  br label %while.cond.0
while.end.0:
  %t9 = load i32, ptr %r
  ret i32 %t9
}

define i32 @main() {
entry:
  %x = alloca i32
  %t0 = call i32 (ptr, ...) @scanf(ptr @.fmt.read, ptr %x)
  br label %until.body.1
until.body.1:
  %t1 = call i32 (ptr, ...) @printf(ptr @.str.0)
  %t2 = load i32, ptr %x
  %t3 = call i32 @fact(i32 %t2)
  %t4 = call i32 (ptr, ...) @printf(ptr @.fmt.int, i32 %t3)
  %t5 = load i32, ptr %x
  %t6 = sub i32 %t5, 2
  store i32 %t6, ptr %x
  %t7 = load i32, ptr %x
  %t8 = icmp slt i32 %t7, 0
  br i1 %t8, label %until.end.1, label %until.body.1
until.end.1:
  %t9 = load i32, ptr @calls
  %t10 = call i32 (ptr, ...) @printf(ptr @.fmt.int, i32 %t9)
  ret i32 0
}
```

### 8.3. Правила

- **SSA без боли:** каждая переменная — это `alloca` + `load`/`store`. Все
  `alloca` ставьте в блоке `entry` (отдельный буфер в `MethodBuilder`),
  а не в месте объявления: `alloca` в теле цикла растит стек на каждой
  итерации. `phi` руками нужен только для короткого `&&`/`||` (ниже) или не
  нужен вовсе, если результат писать во временную `alloca i1`.
- **Выражение возвращает регистр.** Удобный контракт (образец —
  `NodeValue{type, irType, operand, code}` в GSL → LLVM):
  `visit` возвращает имя `%tN` или константу, а код дописывает в текущий блок.
- **Терминаторы.** Каждый базовый блок заканчивается ровно одним `br`/`ret`.
  Держите в emitter флаг `terminated`: перед новой меткой пишите
  `br label %L`, только если блок не закрыт; после `ret` ничего не пишите до
  следующей метки. В прошлом году это проверяли **регуляркой по тексту**
  (`matches("ret ...")`), и на многострочных ветках после `ret` появлялся `br`.
  Код собирался лишь благодаря именам `%tN`: с числовыми `%3` clang его
  отвергает.
- **`ptr` вместо `i8*`/`i32*`.** С LLVM 15 указатели непрозрачные. Старый
  синтаксис ещё парсится, но именно он скрыл у двух студентов ошибки длины строк.
- **Строки:** `[N x i8]`, где **N = число байт UTF-8 + 1** для `\00`. Всё вне
  ASCII экранируйте как `\XX`. С `Привет` длина 13, а не 7; при неверной длине
  clang выдаёт `constant expression type mismatch`.
- **Короткое `&&`:**

    ```llvm
      %t2 = icmp ne i32 %t1, 0
      br i1 %t2, label %and.rhs.0, label %and.end.0
    and.rhs.0:
      %t3 = call i1 @f()
      br label %and.end.0
    and.end.0:
      %t4 = phi i1 [ false, %entry ], [ %t3, %and.rhs.0 ]
    ```

    В `phi` указывается блок, **из которого** пришёл переход. Если правая часть
    сама содержит ветвления, это последний блок правой части, а не `%and.rhs.0`.

- **printf и типы:** `float` расширяйте через `fpext` до `double`, `i1` через
  `zext` до `i32`. Ввод — `scanf("%d", ptr %x)` прямо в `alloca` переменной.
- **Математика:** `declare double @llvm.sqrt.f64(double)` или `@sin`/`@pow`
  из libm (на Linux линкуйте с `-lm`).
- **Глобальные** `@g = global i32 0`, сложная инициализация через `store` в
  начале `main`. **`main` возвращает `i32`**.
- **По ссылке:** параметр типа `ptr` сам и есть адрес переменной вызывающего
  кода: `load`/`store` через него, без своей `alloca`.
- **Составные типы** — в `runtime.c`, в IR только `ptr`. Не объявляйте в IR
  структуры, которые не совпадают со структурами C.
- Для Python можно взять `llvmlite.ir` (`IRBuilder`, `block.is_terminated`,
  автоматические имена), для Java текстовый emitter проще, чем обёртки LLVM.

## 9. Байт-код CPython (.pyc) { #cpython }

### 9.1. Инструменты и версия

Опкоды CPython **меняются в каждой минорной версии** (3.10 → 3.11 → 3.12 →
3.13). Библиотека `bytecode` от этого не спасает: она берёт имена опкодов у
интерпретатора, на котором запущена. Из трёх работ прошлого года одна
работала только на 3.10, другая только на 3.12, на 3.13 она падала с segfault.

**Зафиксируйте одну версию, например 3.12,** и проверяйте её в компиляторе:

```bash
uv venv -p 3.12 .venv && source .venv/bin/activate
pip install antlr4-python3-runtime==4.13.2 bytecode
python compiler.py prog.lang -o build/prog.pyc
cp runtime/lang_runtime.py build/
python build/prog.pyc < in.txt
python -c "import marshal,dis,sys; dis.dis(marshal.loads(open(sys.argv[1],'rb').read()[16:]))" build/prog.pyc
```

**Главный инструмент отладки — `dis`.** Прежде чем генерировать конструкцию,
посмотрите, как её компилирует сам CPython той же версии:

```bash
python -c "import dis; dis.dis(compile('for i in x:\n  f(i)\ng()', 's', 'exec'))"
```

В прошлом году это сразу показало бы обе фатальные ошибки: пропущенный
`END_FOR` после цикла и пропущенный `POP_TOP` после вызова-оператора.

### 9.2. Сквозной пример (генератор на библиотеке `bytecode`)

Здесь целевой код — это объекты `Instr`/`Label`. Листинг показывает, **что**
должен выдавать ваш visitor. Проверено на CPython 3.12.9 и `bytecode` 0.19.

```python
import importlib.util, marshal, struct, sys, time
from bytecode import (Bytecode, Instr, Label, Compare, CompilerFlags,
                      BinaryOp, Intrinsic1Op)

assert sys.version_info[:2] == (3, 12), "опкоды ниже — для CPython 3.12"

def fact_code():
    bc = Bytecode()
    bc.name = bc.qualname = "fact"
    bc.filename = "prog.lang"
    bc.argcount = 1
    bc.argnames = ["n"]
    bc.flags = CompilerFlags.OPTIMIZED | CompilerFlags.NEWLOCALS
    top, end = Label(), Label()
    bc.extend([
        Instr("RESUME", 0),
        Instr("LOAD_GLOBAL", (False, "calls")),         # calls = calls + 1
        Instr("LOAD_CONST", 1),
        Instr("BINARY_OP", BinaryOp.ADD),
        Instr("STORE_GLOBAL", "calls"),
        Instr("LOAD_CONST", 1), Instr("STORE_FAST", "r"),
        top,                                            # while n > 1
        Instr("LOAD_FAST", "n"), Instr("LOAD_CONST", 1),
        Instr("COMPARE_OP", Compare.GT),
        Instr("POP_JUMP_IF_FALSE", end),
        Instr("LOAD_FAST", "r"), Instr("LOAD_FAST", "n"),
        Instr("BINARY_OP", BinaryOp.MULTIPLY), Instr("STORE_FAST", "r"),
        Instr("LOAD_FAST", "n"), Instr("LOAD_CONST", 1),
        Instr("BINARY_OP", BinaryOp.SUBTRACT), Instr("STORE_FAST", "n"),
        Instr("JUMP_BACKWARD", top),
        end,
        Instr("LOAD_FAST", "r"),
        Instr("RETURN_VALUE"),
    ])
    return bc.to_code()

def module_code():
    bc = Bytecode()
    bc.name = "<module>"
    bc.filename = "prog.lang"
    top, out = Label(), Label()
    bc.extend([
        Instr("RESUME", 0),
        # from lang_runtime import *   — runtime импортирует сам .pyc
        Instr("LOAD_CONST", 0), Instr("LOAD_CONST", ("*",)),
        Instr("IMPORT_NAME", "lang_runtime"),
        Instr("CALL_INTRINSIC_1", Intrinsic1Op.INTRINSIC_IMPORT_STAR),
        Instr("POP_TOP"),
        Instr("LOAD_CONST", 0), Instr("STORE_NAME", "calls"),
        Instr("LOAD_CONST", fact_code()),               # вложенный code object
        Instr("MAKE_FUNCTION", 0), Instr("STORE_NAME", "fact"),
        Instr("PUSH_NULL"), Instr("LOAD_NAME", "read_int"), Instr("CALL", 0),
        Instr("STORE_NAME", "x"),
        top,                                            # repeat
        Instr("PUSH_NULL"), Instr("LOAD_NAME", "write_str"),
        Instr("LOAD_CONST", "fact = "), Instr("CALL", 1),
        Instr("POP_TOP"),                               # вызов-оператор!
        Instr("PUSH_NULL"), Instr("LOAD_NAME", "write_int"),
        Instr("PUSH_NULL"), Instr("LOAD_NAME", "fact"),
        Instr("LOAD_NAME", "x"), Instr("CALL", 1),
        Instr("CALL", 1), Instr("POP_TOP"),
        Instr("LOAD_NAME", "x"), Instr("LOAD_CONST", 2),
        Instr("BINARY_OP", BinaryOp.SUBTRACT), Instr("STORE_NAME", "x"),
        Instr("LOAD_NAME", "x"), Instr("LOAD_CONST", 0),  # until x < 0
        Instr("COMPARE_OP", Compare.LT),
        Instr("POP_JUMP_IF_TRUE", out),                 # условные переходы — только вперёд
        Instr("JUMP_BACKWARD", top),
        out,
        Instr("PUSH_NULL"), Instr("LOAD_NAME", "write_int"),
        Instr("LOAD_NAME", "calls"), Instr("CALL", 1), Instr("POP_TOP"),
        Instr("RETURN_CONST", None),
    ])
    return bc.to_code()

def write_pyc(code, path):
    with open(path, "wb") as f:
        f.write(importlib.util.MAGIC_NUMBER)
        f.write(struct.pack("<III", 0, int(time.time()), 0))  # flags, mtime, size — PEP 552
        marshal.dump(code, f)

write_pyc(module_code(), sys.argv[1])
```

```python
# lang_runtime.py — лежит рядом с .pyc
import sys
_tokens = iter(sys.stdin.read().split())
def read_int(): return int(next(_tokens))
def write_int(x): print(x)
def write_str(s): print(s, end="")
```

### 9.3. Правила (CPython 3.12)

- **Вызов:** `PUSH_NULL` → функция → аргументы → `CALL n`. Для оператора
  `f(x);` дальше идёт `POP_TOP`.
- **Переменные:** на уровне модуля `LOAD_NAME`/`STORE_NAME`, в функции
  `LOAD_FAST`/`STORE_FAST` для локальных и `LOAD_GLOBAL`/`STORE_GLOBAL` для
  глобальных. Что есть что, решает **таблица символов из семантики**.
  Правило «в функции всё `FAST`» ломает чтение глобальных.
- **Функции:** отдельный `Bytecode` с заполненными `name`, `filename`,
  `argcount`, `argnames`, `flags = OPTIMIZED | NEWLOCALS`, затем
  `LOAD_CONST <code>` + `MAKE_FUNCTION 0` + `STORE_NAME`.
- **Переходы:** в 3.12 `POP_JUMP_IF_*` только вперёд, назад — `JUMP_BACKWARD`.
  Для `until` инвертируйте условие, как в примере.
- **`for ... in`:** `GET_ITER; L: FOR_ITER END; STORE; <тело>; JUMP_BACKWARD L;
  END: END_FOR`. Без `END_FOR` исчерпанный итератор «перепрыгивает» первую
  инструкцию после цикла.
- **`and`/`or` коротко:** `COPY 1; POP_JUMP_IF_FALSE END; POP_TOP; <b>; END:`.
- **Операции:** `BINARY_OP` с аргументом из `bytecode.BinaryOp`, сравнения
  через `COMPARE_OP` с `bytecode.Compare`.
- **Заголовок .pyc (PEP 552):** `MAGIC_NUMBER | flags=0 | mtime | size`.
  Проверяйте и `python prog.pyc`, и `import prog`: при неправильном порядке
  полей первое работает, а второе нет.
- **Runtime** импортируйте **внутри** .pyc (`IMPORT_NAME`), а не подсовывайте
  через `runpy.run_path(init_globals=...)`. Иначе `python prog.pyc` падает с
  `NameError`.
- Удобно (но не обязательно) иметь текстовый дамп — свой «ассемблер», как
  `.pyasm` в MCL → CPython (`assembler.py` поверх библиотеки `bytecode`).
  Его легко читать в отчёте и сравнивать в тестах.

## 10. Проверка и сдача { #proverka }

### 10.1. Тесты: сравнивайте вывод, а не факт генерации

В прошлом году тест «сгенерированный `.wat` длиннее 100 байт» проходил у
компилятора, который вместо строк генерировал `i32.const 0`. Проверяйте то,
что видит пользователь:

```text
examples/
  fact.lang          # программа
  fact.in            # stdin (если нужен)
  fact.expected      # ожидаемый stdout
```

```bash
#!/usr/bin/env bash
# tests/run.sh — компиляция, сборка, запуск и сравнение для всех примеров
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for src in examples/*.lang; do
  base="${src%.lang}"
  [[ -f "$base.expected" ]] || continue
  ./compile.sh "$src" > /dev/null                 # ваш компилятор + ассемблер
  input="$base.in"; [[ -f "$input" ]] || input=/dev/null
  if ./run.sh "$src" < "$input" | diff -u "$base.expected" - ; then
    echo "OK   $src"
  else
    echo "FAIL $src"; fail=1
  fi
done
exit $fail
```

Для Python-компиляторов то же удобно писать на `pytest` через
`subprocess.run(..., input=..., capture_output=True)`. Лучший образец
прошлого года — unit-тесты работы Lisp → WAT: каждый тест компилирует фрагмент,
исполняет его в `wasmtime` и сравнивает результат (`assert_evaluates("(or nil 5)", 5.0)`).

Минимальный набор тестов генерации:

- арифметика с приоритетами и скобками, смешанные `int`/`float`;
- `if` без `else` и с `else`, вложенные циклы, `break`/`continue`;
- `until`, выполняющийся ровно один раз;
- рекурсивная функция (факториал / Фибоначчи);
- глобальная переменная, изменяемая из функции;
- передача по ссылке / результату, если это есть в варианте;
- `a, b = b, a`, если есть множественное присваивание;
- короткое вычисление: `false && f()` не вызывает `f`;
- строка с кириллицей;
- выражение глубиной 15–20 скобок (ловит маленький `.limit stack` / `.maxstack`);
- вложенная индексация `a[b[i]]` (ловит общие временные переменные).

### 10.2. Чек-лист перед Pull Request

- [ ] Генератор запускается только если нет синтаксических и семантических ошибок.
- [ ] Генератор не выводит типы заново, а берёт их из семантики.
- [ ] Все обязательные конструкции генерируются: `if-else`, `while`, `until`,
      `for`, функции с параметрами и `return`, глобальные и локальные
      переменные, `read`/`write`, явное приведение типов.
- [ ] Логические операторы вычисляются по короткой схеме.
- [ ] Вызов функции как оператора не оставляет значение на стеке.
- [ ] Неподдерживаемая конструкция вызывает **ошибку компилятора**, а не
      молча превращается в `0`, `";; unimpl"` или `nop`.
- [ ] Выход проверен инструментом платформы: `wat2wasm` / `java` (верификатор) /
      `ilasm` + `dotnet` / `opt -passes=verify` / `python` + `import`.
- [ ] Runtime собирается скриптом из исходников, бинарные `.dll`/`.jar`/`.class`
      не коммитятся.
- [ ] Нет абсолютных путей (`C:\...`, `/home/...`) ни в скриптах, ни в
      генерируемых файлах.
- [ ] `compile.sh <файл>` проходит на чистой машине по инструкции из README.
- [ ] Для каждого примера в `examples/` есть `.expected`, тест-раннер
      завершается с ненулевым кодом при расхождении.
- [ ] В отчёте есть: таблица отображения типов языка на типы платформы,
      схема трансляции каждой управляющей конструкции, фрагмент исходника
      рядом со сгенерированным кодом, описание runtime-библиотеки.

## 11. Что почитать

- Лекции курса: [10. Генерация промежуточного кода](../lectures/html/10-generaciya-promezhutochnogo-koda.html),
  [12. Синтаксически управляемая трансляция](../lectures/html/12-sintaksicheski-upravlyaemaya-translyaciya.html).
- Ахо, Сети, Ульман. *Компиляторы*, главы о генерации промежуточного кода
  (см. [Источники](../languages/sources.md#aho-sethi-ullman)).
- WebAssembly: [спецификация текстового формата](https://webassembly.github.io/spec/core/text/index.html),
  [MDN: Understanding WebAssembly text format](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Understanding_the_text_format).
- JVM: [The Java Virtual Machine Specification, глава 6 (инструкции)](https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-6.html),
  [Jasmin](https://jasmin.sourceforge.net/).
- CIL: стандарт [ECMA-335](https://ecma-international.org/publications-and-standards/standards/ecma-335/),
  раздел Partition III — список инструкций.
- LLVM: [LLVM Language Reference](https://llvm.org/docs/LangRef.html),
  учебник [Kaleidoscope](https://llvm.org/docs/tutorial/).
- CPython: [документация модуля `dis`](https://docs.python.org/3.12/library/dis.html)
  (список опкодов вашей версии), [библиотека `bytecode`](https://bytecode.readthedocs.io/).

Разбор других решений прошлого года (грамматика, ошибки, семантика, тесты):
[Решения прошлого года](past-works.md).
