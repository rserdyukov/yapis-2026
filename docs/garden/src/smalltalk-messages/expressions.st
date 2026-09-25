"Выражения для Playground (Pharo): выделить строку и выполнить Print it.
 После >>> — ожидаемый результат по документации; не запускалось."

" --8<-- [start:precedence]"
3 + 4 * 2.                 ">>> 14   бинарные — строго слева направо"
3 + (4 * 2).               ">>> 11"
3 + 4 factorial.           ">>> 27   унарное factorial раньше бинарного +"
2 raisedTo: 1 + 2.         ">>> 8    бинарное + раньше ключевого raisedTo:"
3 max: 2 * 5 - 1.          ">>> 9"
5 between: 1 and: 2 * 3.   ">>> true   один селектор between:and:"
" --8<-- [end:precedence]"

" --8<-- [start:everything-object]"
3 class.                   ">>> SmallInteger"
100 factorial class.       ">>> LargePositiveInteger"
(3 > 2) class.             ">>> True"
nil class.                 ">>> UndefinedObject"
[:x | x + 1] class.        ">>> BlockClosure   (в Smalltalk-80 — BlockContext)"
3 class class.             ">>> SmallInteger class   метакласс"
3 class class class.       ">>> Metaclass"
Metaclass class class.     ">>> Metaclass   цепочка «экземпляр-класс» замкнулась"
3 perform: #+ with: 4.     ">>> 7   селектор — тоже объект (Symbol)"
3 respondsTo: #factorial.  ">>> true"
" --8<-- [end:everything-object]"

" --8<-- [start:control]"
(17 * 13 > 220)
    ifTrue: [ 'bigger' ]
    ifFalse: [ 'smaller' ].          ">>> 'bigger'"

| n result |
n := 1.
[ n < 1000 ] whileTrue: [ n := n * 2 ].
n.                                   ">>> 1024   whileTrue: посылается блоку"

result := String new.
1 to: 5 do: [ :i | result := result , i printString , ' ' ].
result.                              ">>> '1 2 3 4 5 '   to:do: посылается числу"

#(1 2 3 4) inject: 0 into: [ :sum :each | sum + each ].   ">>> 10"
(1 to: 5) collect: [ :each | each * each ].               ">>> #(1 4 9 16 25)"
" --8<-- [end:control]"

" --8<-- [start:closure]"
| makeCounter c1 c2 |
makeCounter := [ | count | count := 0. [ count := count + 1 ] ].
c1 := makeCounter value.
c2 := makeCounter value.
c1 value. c1 value.
c1 value.                  ">>> 3"
c2 value.                  ">>> 1   у каждого замыкания своя count"
" --8<-- [end:closure]"

" --8<-- [start:cascade]"
OrderedCollection new add: 1; add: 2; yourself.   ">>> an OrderedCollection(1 2)"
" --8<-- [end:cascade]"
