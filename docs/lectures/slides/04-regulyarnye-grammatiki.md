---
type: slide
publish: true
theme: custom_academic
paginate: "true"
---
<!-- _class: lead -->
<!-- _paginate: skip -->
# Регулярные грамматики 
## и конечные автоматы

---
## Определение
- Регулярная грамматика (тип‑3 по Хомскому): правила только вида
  - Праволинейная: $A \to a$ или $A \to aB$
  - Леволинейная: $A \to a$ или $A \to Ba$
  - Разрешается $A \to \epsilon$ (обычно только для начального символа и не встречается в правых частях)
- Правая и левая линейности эквивалентны по выразительной силе
- Эквивалентные модели: регулярные выражения и конечные автоматы

---
## Где встречаются
- Лексический анализ (распознавание токенов)
- Поиск по шаблону в строках
- Простейшие протоколы и форматы
- Примеры языков: $a^*b^*$, все слова над $\{0,1\}$ с чётным числом нулей, все идентификаторы `[_A-Za-z][_A-Za-z0-9]*`

---
## Пример языка и грамматики
- Язык: все слова из `a` и `b`, оканчивающиеся на `a`
- Грамматика (праволинейная):
  - $S \to aA \mid bA$
  - $A \to aA \mid bA \mid a$
- Порождает: `a`, `ba`, `aba`, `bba`, `abba`, …

---
## Вывод по грамматике (пример)
- Цель: вывести `abba`
- Вывод: $S \Rightarrow aA \Rightarrow abA \Rightarrow abbA \Rightarrow abba$
- Замечание: дерево вывода для регулярной грамматики вырождено (глубина линейная)

---
## Вывод по грамматике (пример)
```plantuml
digraph SyntacsTree {
	fontname="Helvetica,Arial,sans-serif"
	node [fontname="Helvetica,Arial,sans-serif"]
	edge [fontname="Helvetica,Arial,sans-serif"]
	node [shape=box];  {node [label="A"] A0; A1; A2}; S
	node [shape=circle]; {node [label="a"] a0; a1}; {node [label="b"] b0; b1};
	S->a0;
	S->A0;
	{ rank=same; a0 -> A0 [style=invis]; }
	A0->b0;
	A0->A1;
	{ rank=same; b0 -> A1 [style=invis]; }
	A1->b1
	A1->A2
	{ rank=same; b1 -> A2 [style=invis]; }
	A2->a1;
}
```

---
## Практика: от регулярки к грамматике
- Регулярка `1*(01*01*)*`
- Грамматика:
  - $S \to 1S \mid 0A \mid \epsilon$
  - $A \to 1B$
  - $B \to 1B \mid 0S$

---
## Регулярные выражения: базовая запись
- Алфавит $\Sigma$; операции:
  - Конкатенация: $rs$
  - Альтернация: $r \mid s$
  - Замыкание Клини: $r^*$ (0+ повторов)
  - Скобки для группировки
- Приоритет: $^*$ выше конкатенации, конкатенация выше $\mid$

---
## Расширенные операторы
- `r+` — 1+ повторов; `r?` — 0 или 1; `{n}`, `{n,}`, `{n,m}` — кратности
- Символьные классы:
	- `[a-z]`, отрицание `[^0-9]`
	- \d \D \w \W \s \S
- Якоря строки: `^`, `$`; точка `.` — любой символ
- Группы: `(...)`, именованные/незахватывающие `(?:...)` (зависят от реализации)

---
## Примеры регулярных выражений
- Язык «заканчивается на a»: `(a|b)*a`
- Идентификатор: `[A-Za-z_][A-Za-z0-9_]*`

Полезные сайты:
- https://regexone.com/
- https://regex101.com/

---
## Преобразования и тождеcтва
- Ассоциативность: $(rs)t = r(st)$, $(r|s)|t = r|(s|t)$
- Дистрибутивность: $r(s|t) = rs|rt$
- Идемпотентность: $r|r = r$
- Нейтральные элементы: $r\epsilon = \epsilon r = r$, $r|\emptyset = r$

---
## Реализация регулярных выражений: Python
```python
import re
pat = re.compile(r'^(?:a|b)*a$')
print(bool(pat.fullmatch('abba')))  # True
print(bool(pat.fullmatch('abb')))   # False
```

---
## Реализация регулярных выражений: C++
```cpp
#include <regex>
#include <string>
#include <iostream>

int main() {
  std::regex re("^(?:a|b)*a$");
  std::cout << std::regex_match(std::string("abba"), re) << "\n"; // 1
  std::cout << std::regex_match(std::string("abb"), re) << "\n";  // 0
}
```


---
## Конечные автоматы: определение
- DFA: $\langle Q,\, \Sigma,\, \delta,\, q_0,\, F\rangle$
  - $\delta: Q\times\Sigma\to Q$
- NFA: $\langle Q,\, \Sigma,\, \Delta,\, q_0,\, F\rangle$
  - $\Delta: Q\times (\Sigma\cup\{\epsilon\}) \to 2^Q$
- Язык автомата — множество слов, принимаемых из $q_0$ в одно из $F$

---
## Способы записи автоматов
- Диаграмма переходов (ориентированный граф)
- Таблица переходов
- Текстовое задание функции перехода

---
## Пример DFA для `(a|b)*a`
```plantuml
digraph finite_state_machine {
	fontname="Helvetica,Arial,sans-serif"
	node [fontname="Helvetica,Arial,sans-serif"]
	edge [fontname="Helvetica,Arial,sans-serif"]
	rankdir=LR;
	node [shape = circle]; S;
	node [shape = doublecircle]; F;
	S -> F [label = "a"];
	S -> S [label = "b"];
	F -> F [label = "a"];
	F -> S [label = "b"];
}
```

---
## Таблица переходов (пример)

| Состояние | a | b |
|---|---|---|
| S | F | S |
| F | F | S |

---
## Преобразование конечных автоматов
- Из NFA -> DFA
- Минимизация DFA

---
<!-- _class: lead -->
# Вопросы
