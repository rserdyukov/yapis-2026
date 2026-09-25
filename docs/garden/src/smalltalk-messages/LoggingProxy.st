"Прокси через doesNotUnderstand: — по Pharo by Example 9, гл. «Reflection»,
 раздел «Lightweight proxies». Упрощено: цель передаётся явно, без become:."

" --8<-- [start:proxy]"
ProtoObject subclass: #LoggingProxy
    instanceVariableNames: 'subject invocationCount'
    classVariableNames: ''
    package: 'Garden-Messages'

LoggingProxy class >> on: anObject
    ^ self new setSubject: anObject

LoggingProxy >> setSubject: anObject
    subject := anObject.
    invocationCount := 0

LoggingProxy >> invocationCount
    ^ invocationCount

LoggingProxy >> doesNotUnderstand: aMessage
    "Сюда попадает любое сообщение, для которого поиск метода ничего не нашёл."
    Transcript show: 'performing ', aMessage printString; cr.
    invocationCount := invocationCount + 1.
    ^ aMessage sendTo: subject
" --8<-- [end:proxy]"

" --8<-- [start:proxy-use]"
| p |
p := LoggingProxy on: OrderedCollection new.
p add: 3; add: 4.
p includes: 4.             ">>> true"
p invocationCount.         ">>> 3"
" --8<-- [end:proxy-use]"
