---
publish: true
title: "Задача 3. Предиктивный анализатор"
---

<!-- Перенесено из Google Docs «Практические задачи» (2026-09-24).
     Источник правды теперь этот файл; рисунки — docs/practice/img/. -->

# Задача 3. Построение таблицы предиктивного анализатора

*[Практические занятия](index.md#tema-2) · слайды: [06. Построение синтаксического анализатора](../lectures/html/06-postroenie-sintaksicheskogo-analizatora.html) ·
[условие](#uslovie) · [варианты](#varianty) · [пример решения](#primer)*

## Теоретические сведения { #teoriya }

<strong>Предиктивный анализ</strong> – анализ, при котором сканируемый символ однозначно определяет процедуру, выбранную для каждого нетерминала.

<strong>Предиктивный анализатор</strong> представляет собой программу, содержащую процедуры для каждого нетерминального символа.

При построении предиктивного синтаксического анализатора можно создать его план в виде <strong>диаграммы переходов</strong>.

<strong>Диаграмма переходов</strong> – стилизованная блок-схема, которая изображает действия, выполняемые лексическим анализатором при вызове его синтаксическим анализатором для получения очередного токена.

Для построения диаграммы переходов предиктивного синтаксического анализатора на основе грамматики вначале следует устранить из нее левые рекурсии, а затем провести левую факторизацию. После этого для каждого нетерминала <strong>А</strong> выполняется следующее:

1. Создаем начальное и заключительное состояния.
1. Для каждой продукции <strong>А →Х<sub>1</sub>Х<sub>2</sub>…Х<sub>n</sub></strong> создаем путь от начального к заключительному состоянию с дугами, помеченными как <strong>Х<sub>1</sub>, Х<sub>2</sub>, …, Х<sub>n</sub></strong>.

<strong>FIRST и FOLLOW</strong>

Если <strong>α</strong> – произвольная строка символов грамматики, то определим <strong>FIRST(α)</strong> как множество терминалов, с которых начинаются строки, выводимые из <strong>α</strong>. Если <strong>α → ε</strong>, то <strong>ε € FIRST(α)</strong>.

Определим <strong>FOLLOW(A)</strong> для нетерминала <strong>А</strong> как множество терминалов, которые могут располагаться непосредственно справа от <strong>А</strong> в некоторой сентенциальной форме, т е множество терминалов <strong>а</strong>, таких, что существует порождения вида <strong>S=&gt;αAaβ</strong> для некоторых <strong>α</strong> и <strong>β</strong>.

Чтобы <strong>вычислить FOLLOW(A)</strong> для всех нетерминалов <strong>А</strong>, будем применять следующие правила до тех пор, пока ни к одному множеству <strong>FOLLOW</strong> нельзя будет добавить ни одного символа.

1. Поместим <strong>$</strong> в <strong>FOLLOW(S)</strong>, где <strong>S</strong> – стартовый символ, а <strong>$</strong> - правый ограничитель входного потока.
1. Если имеется продукция <strong>А → αВβ</strong>, то все элементы множества <strong>FIRST(β)</strong>, кроме ε помещаются в множество <strong>FOLLOW(В)</strong>.
1. Если имеется продукция <strong>А → αВ</strong> или <strong>А →αВβ,</strong> где <strong>FIRST(β)</strong> содержит <strong>ε</strong>, то все элементы из множества <strong>FOLLOW(А)</strong> помещаются в множество <strong>FOLLOW(В)</strong>.

Чтобы вычислить <strong>FIRST(X)</strong> для всех символов грамматики <strong>Х</strong>, будем применять следующее правило до тех пор, пока ни к одному из множеств <strong>FIRST</strong> не смогут быть добавлены ни терминалы, ни <strong>ε</strong>:

1. Если <strong>Х</strong> – терминал, то <strong>FIRST(X) = {X}</strong>.
1. Если имеется продукция <strong>Х → ε</strong>, добавим <strong>ε</strong> к <strong>FIRST(X)</strong>.
1. Если <strong>Х</strong> – нетерминал и имеется продукция <strong>Х → Y<sub>1</sub>Y<sub>2</sub>…Y<sub>k</sub></strong>, то поместим <strong>а</strong> в <strong>FIRST(X)</strong>, если для некоторого <strong>i a € FIRST(Y<sub>i</sub>)</strong> и <strong>ε</strong> входит во все множества <strong>FIRST(Y<sub>1</sub>), …, FIRST(Y<sub>i-1</sub>)</strong>, т е <strong>Y<sub>1</sub> … Y<sub>i-1</sub> =&gt;ε</strong>. Если ε имеется во всех <strong>FIRST(Y<sub>i</sub>), i=1..k</strong>, то добавляем <strong>ε</strong> к <strong>FIRST(X)</strong>.

Теперь можно вычислить <strong>FIRST</strong> для любой строки <strong>Х<sub>1</sub>Х<sub>2</sub>… Х<sub>n</sub></strong> следующим образом. Добавим к <strong>FIRST(Х<sub>1</sub>Х<sub>2</sub>… Х<sub>n</sub>)</strong> все <strong>не-ε</strong> символы из <strong>FIRST(Х<sub>1</sub>)</strong>. Добавим также все <strong>не-ε</strong> символы из <strong>FIRST(Х<sub>2</sub>)</strong>, если <strong>ε € FIRST(Х<sub>1</sub>)</strong>, все <strong>не-ε</strong> символы из <strong>FIRST(Х<sub>3</sub>)</strong>, если ε имеется как в <strong>FIRST(Х<sub>1</sub>)</strong>, так и в <strong>FIRST(Х<sub>2</sub>)</strong> и т д. Добавим <strong>FIRST(Х<sub>1</sub>Х<sub>2</sub>… Х<sub>n</sub>)</strong>, если для всех <strong>i FIRST(Х<sub>i</sub>)</strong> содержит <strong>ε</strong>.

<strong>Алгоритм «Построение таблицы предиктивного анализатора»</strong>

<strong>Вход:</strong>

Грамматика <strong>G</strong>.

<strong>Выход:</strong>

Таблица анализа <strong>М</strong>.

<strong>Метод:</strong>

1. Для каждой продукции грамматики <strong>А → α</strong> выполняем шаги <strong>2</strong> и <strong>3</strong>.
1. Для каждого терминала <strong>а</strong> из <strong>FIRST(α)</strong> добавляем <strong>А → α</strong> в ячейку <strong>М\[A,a\]</strong>.
1. Если в <strong>FIRST(α)</strong> входит <strong>ε</strong>, для каждого терминала <strong>b</strong> из <strong>FOLLOW(А)</strong> добавим <strong>А → α</strong> в ячейку <strong>М\[A,b\]</strong>. Если <strong>ε</strong> входит в <strong>FIRST(α)</strong>, а <strong>$</strong> - в <strong>FOLLOW(А)</strong>, добавим <strong>А → α</strong> в ячейку <strong>М\[A,$\]</strong>.
1. Сделаем каждую неопределенную ячейку таблицы <strong>М</strong> указывающей на ошибку.

## Условие { #uslovie }

1. По описанию языка построить <strong>КС</strong>-грамматику.
1. Определить свойства полученной грамматики.
1. Если грамматика не обладает свойствами, требуемыми для построения таблицы предиктивного анализатора, то преобразовать грамматику к требуемой форме.
1. Определить значение функций <strong>FIRST</strong> и <strong>FOLLOW</strong> для разработанной грамматики.
1. Построить таблицу предиктивного анализатора.
1. Проверить правильность построения на трех примерах (один правильный, два неправильных).

## Варианты { #varianty }

| № | Формулировка варианта задания |
|---|---|
| 1 | &lt;E&gt; ::= &lt;E&gt; ‘+’ &lt;E&gt; \| &lt;E&gt; ‘\*’ &lt;E&gt; \| ‘(‘ &lt;E&gt; ‘)’ \| ‘i’ |
| 2 | &lt;S&gt; ::= ‘if’ &lt;E&gt; ‘then’ &lt;O&gt; \[ ‘else’ &lt;O&gt; \]<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘==’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ … |
| 3 | ![1](img/task2-17.png){ width="623" }<br>type:<br>![2](img/task2-18.png){ width="136" }<br>formalParameter:<br>![3](img/task2-19.png){ width="165" }<br>block:<br>![4](img/task2-20.png){ width="254" } |
| 4 | ![1](img/task2-21.png){ width="623" } |
| 5 | &lt;P&gt; ::= \[ &lt;H&gt; \] &lt;B&gt;<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 6 | &lt;P&gt; ::= &lt;H&gt; \[ &lt;B&gt; \]<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 7 | &lt;P&gt; ::= \[ &lt;H&gt; \] \[ &lt;B&gt; \]<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 8 | &lt;P&gt; ::=  &lt;H&gt; (&lt;B&gt;)…<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 9 | &lt;P&gt; ::= \[ &lt;H&gt; \] &lt;B&gt;<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… \[‘;’\] |
| 10 | &lt;P&gt; ::= \[ &lt;H&gt; \] &lt;B&gt;<br>&lt;H&gt; ::= \[‘h’\] (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… \[‘;’\] |
| 11 | &lt;P&gt; ::=  &lt;H&gt; \[ &lt;B&gt; \]<br>&lt;H&gt; ::= \[‘h’\] (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ ( \[ ‘,’ \] ‘b’)… ‘;’ |
| 12 | &lt;P&gt; ::=  &lt;H&gt;… \[ &lt;B&gt; \]<br>&lt;H&gt; ::= \[‘h’\] (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ ( \[ ‘,’ \] ‘b’)… \[ ‘;’ \] |
| 13 | &lt;P&gt; ::=  &lt;H&gt; \[ &lt;B&gt;… \]<br>&lt;H&gt; ::= \[‘h’\] (‘t’ ‘i’)…<br>&lt;B&gt; ::= \[‘b’\] ( \[‘,’\] ‘b’)… ‘;’ |
| 14 | &lt;P&gt; ::= (\[ &lt;H&gt; \] \[ &lt;B&gt; \])…<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 15 | &lt;P&gt; ::= (&lt;H&gt; \| &lt;B&gt;)…<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)…<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 16 | &lt;P&gt; ::= &lt;H&gt; \[ &lt;B&gt; \]<br>&lt;H&gt; ::= ‘h’ (‘t’ ‘i’)… \| ε<br>&lt;B&gt; ::= ‘b’ (‘,’ ‘b’)… ‘;’ |
| 17 | &lt;E&gt; ::= &lt;E&gt; ‘-’ &lt;E&gt; \| &lt;E&gt; ‘+’ &lt;E&gt; \| ‘(‘ &lt;E&gt; ‘)’ \| ‘i’ |
| 18 | &lt;S&gt; ::= ‘if’ &lt;E&gt; ‘then’ &lt;O&gt; \[ ‘else’ &lt;O&gt; \]<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 19 | ![1](img/task2-22.png){ width="623" } |
| 20 | h:![1](img/task2-23.png){ width="190" }<br>![2](img/task2-24.png){ width="254" }<br>b:<br>![3](img/task2-25.png){ width="306" } |
| 21 | ![1](img/task2-26.png){ width="242" }<br>h:<br>![2](img/task2-24.png){ width="254" }<br>b:<br>![3](img/task2-25.png){ width="306" } |
| 22 | ![11](img/task2-27.png){ width="267" }<br>h:<br>![2](img/task2-24.png){ width="254" }<br>b:<br>![33](img/task2-28.png){ width="331" } |
| 23 | ![11](img/task2-27.png){ width="267" }<br>h:<br>![22](img/task2-29.png){ width="280" }<br>b:<br>![333](img/task2-30.png){ width="344" } |
| 24 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ( \[ ‘i’ ‘:’ \] ‘then’ &lt;O&gt; )…<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 25 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ( ‘i’ ‘:’ ‘then’ &lt;O&gt; )…<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| ‘o’ |
| 26 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ( ‘i’ ‘:’ ‘then’ &lt;O&gt; )…<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 27 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ‘then’ &lt;O&gt; \| &lt;O&gt;<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 28 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ‘then’ &lt;O&gt; \[ ‘else’ &lt;O&gt; \] \| &lt;O&gt;<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 29 | &lt;S&gt; ::= ‘if’ \[ &lt;E&gt; \] ‘then’ &lt;O&gt; \[ ‘else’ &lt;O&gt; \]<br>&lt;E&gt; ::= ‘i’ \| ‘i’ ‘&lt;&gt;’ &lt;E&gt;<br>&lt;O&gt; ::= ‘o’ &lt;O&gt; \| &lt;S&gt; \| ‘o’ |
| 30 | &lt;E&gt; ::= &lt;E&gt; ‘\*’ &lt;E&gt; \| &lt;E&gt; ‘=’ &lt;E&gt; \| ‘(‘ &lt;E&gt; ‘)’ \| ‘i’ |

## Пример построения таблицы предиктивного анализатора { #primer }

1. Дано описание языка:

```text
<P> ::=  <H> (<B>)…
<H> ::= ‘h’ (‘t’ ‘i’)…
<B> ::= ‘b’ (‘,’ ‘b’)… ‘;’
```

<ol start="2" markdown>
<li markdown="span">По описанию языка построили КС-грамматику:</li>
</ol>

```text
P -> HG            G -> BG                G -> ε
H -> hN            N -> tiN          N -> ε
B -> bM;         M -> ,bM                 M -> ε
```

<ol start="3" markdown>
<li markdown="span">Грамматика нелеворекурсивная и левофакторизованная.</li>
<li markdown="span">Определим значение функций <strong>FIRST</strong> и <strong>FOLLOW</strong> для разработанной грамматики.</li>
</ol>

| Нетерминал | FIRST | FOLLOW |
|---|---|---|
| P | {h} | {$} |
| H | {h} | {b, $} |
| N | {t, ε} | {b, $} |
| M | {,, ε} | {;} |
| B | {b} | {b, $} |
| G | {b, ε} | {$} |

<ol start="5" markdown>
<li markdown="span">Построим таблицу предиктивного анализатора.</li>
</ol>

|  | <strong>h</strong> | <strong>ti</strong> | <strong>b</strong> | <strong>,</strong> | <strong>;</strong> | <strong>$</strong> |
|---|---|---|---|---|---|---|
| <strong>P</strong> | P → HG |  |  |  |  |  |
| <strong>H</strong> | H → hN |  |  |  |  |  |
| <strong>N</strong> |  | N → tiN | N → ε |  |  | N → ε |
| <strong>G</strong> |  |  | G → BG |  |  | G → ε |
| <strong>B</strong> |  |  | B → bM; |  |  |  |
| <strong>M</strong> |  |  |  | M → ,bM | M → ε |  |

<ol start="6" markdown>
<li markdown="span">Проверим правильность построения на трех примерах.</li>
</ol>

<strong>Правильные примеры:</strong>

| Разбор <strong>htib;$</strong> | Разбор <strong>htitib,b;$</strong> |
|---|---|
| P$<br>HG$<br>hNG$<br>NG$<br>tiNG$<br>NG$<br>G$<br>BG$<br>bM;G$<br>M;G$<br>;G$<br>G$<br>$ | P$<br>HG$<br>hNG$<br>NG$<br>tiNG$<br>NG$<br>tiNG$<br>NG$<br>G$<br>BG$<br>bM;G$<br>M;G$<br>,bM;G$<br>M;G$<br>;G$<br>G$<br>$ |

Строки разложены.

<strong>Неправильный пример:</strong>

<strong>hbtib,b;$</strong>

| Разбор | Результат |
|---|---|
| P$<br>HG$<br>hNG$<br>NG$<br>tiNG$ | ошибка: в строке есть лишний терминал b |
