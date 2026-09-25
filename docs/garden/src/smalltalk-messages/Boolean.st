"Условный оператор в Smalltalk-80 — не синтаксис, а методы классов True и False.
 Запись по Blue Book, гл. 14 «Kernel Support», раздел «Classes Boolean, True, and False»;
 в книге возврат печатается стрелкой вверх, здесь — ^, как в Squeak и Pharo."

" --8<-- [start:true-false]"
"Boolean — абстрактный класс; true и false — единственные экземпляры его подклассов."

True >> ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock
    ^ trueAlternativeBlock value

True >> ifTrue: trueAlternativeBlock
    ^ trueAlternativeBlock value

True >> ifFalse: falseAlternativeBlock
    ^ nil

False >> ifTrue: trueAlternativeBlock ifFalse: falseAlternativeBlock
    ^ falseAlternativeBlock value

False >> ifTrue: trueAlternativeBlock
    ^ nil

False >> ifFalse: falseAlternativeBlock
    ^ falseAlternativeBlock value
" --8<-- [end:true-false]"

" --8<-- [start:and-or]"
"Короткое замыкание — тоже полиморфизм: аргумент — блок, и вычислять его или нет, решает получатель."

True >> and: alternativeBlock
    ^ alternativeBlock value

False >> and: alternativeBlock
    ^ self

True >> or: alternativeBlock
    ^ self

False >> or: alternativeBlock
    ^ alternativeBlock value
" --8<-- [end:and-or]"
