%% Падение с badmatch, связь (link), trap_exit и монитор.
%% Запуск: erlc crash.erl && erl -noshell -eval 'crash:main(), halt().'
-module(crash).
-export([main/0]).

%% Сценарий выполняется в отдельном процессе, чтобы trap_exit и связи
%% не затрагивали процесс, в котором erl вычисляет -eval.
main() ->
    {_, Ref} = spawn_monitor(fun run/0),
    receive {'DOWN', Ref, process, _, _} -> ok end.


% --8<-- [start:worker]
parse(0) -> {error, zero};
parse(N) -> {ok, N}.

worker(N) ->
    {ok, _Value} = parse(N),   % «счастливый путь»: при {error, zero} — исключение badmatch
    ok.                        % функция закончилась — процесс завершается с причиной normal
% --8<-- [end:worker]

% --8<-- [start:main]
run() ->
    process_flag(trap_exit, true),     % сигналы выхода станут сообщениями {'EXIT', Pid, Reason}

    P1 = spawn_link(fun() -> worker(7) end),
    receive {'EXIT', P1, R1} -> io:format("worker(7) exit: ~p~n", [R1]) end,

    P2 = spawn_link(fun() -> worker(0) end),
    receive {'EXIT', P2, {R2, _Stack}} -> io:format("worker(0) exit: ~p~n", [R2]) end,

    %% Промежуточный процесс не перехватывает выходы: связь убивает и его.
    {Mid, Ref} = spawn_monitor(fun() ->
                                       spawn_link(fun() -> worker(0) end),
                                       receive after infinity -> ok end
                               end),
    receive
        {'DOWN', Ref, process, Mid, {R3, _}} -> io:format("middle died too: ~p~n", [R3])
    end.
% --8<-- [end:main]
