%% Лёгкий процесс, асинхронные сообщения и выборочный receive.
%% Запуск: erlc messages.erl && erl -noshell -eval 'messages:main(), halt().'
-module(messages).
-export([main/0]).

%% Сценарий выполняется в отдельном процессе с чистым почтовым ящиком.
main() ->
    {_, Ref} = spawn_monitor(fun run/0),
    receive {'DOWN', Ref, process, _, _} -> ok end.

% --8<-- [start:counter]
counter(N) ->
    receive
        {add, K}    -> counter(N + K);            % хвостовой вызов: цикл без роста стека
        {get, From} -> From ! {count, N}, counter(N)
    end.
% --8<-- [end:counter]

% --8<-- [start:main]
run() ->
    Self = self(),
    Pid = spawn(fun() -> counter(0) end),         % новый процесс со своей кучей
    Pid ! {add, 5},                               % отправка не ждёт получателя
    Pid ! {add, 7},
    Pid ! {get, Self},                            % порядок от одного отправителя сохраняется
    receive {count, N} -> io:format("count = ~p~n", [N]) end,

    %% Выборочный приём: сначала берём {high, _}, остальное остаётся в очереди.
    self() ! {low, 1}, self() ! {high, 2}, self() ! {low, 3},
    First = receive {high, X} -> X end,
    io:format("first high = ~p, rest = ~p~n", [First, drain()]).
% --8<-- [end:main]

drain() ->
    receive M -> [M | drain()] after 0 -> [] end.
