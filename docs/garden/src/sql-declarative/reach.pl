% Та же достижимость в Prolog (SWI-Prolog). Без директивы table
% левая рекурсия на цикле a -> b -> a уходит в бесконечный спуск.
% Запуск: swipl -g "forall(reach(X,Y), (write(X-Y), nl)), halt" reach.pl
% --8<-- [start:reach]
:- table reach/2.            % убрать эту строку — поиск не завершится

edge(a, b).
edge(b, a).
edge(b, c).

reach(X, Y) :- edge(X, Y).
reach(X, Z) :- reach(X, Y), edge(Y, Z).
% --8<-- [end:reach]
