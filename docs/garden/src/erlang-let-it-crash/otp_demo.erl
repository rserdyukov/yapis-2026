%% Сценарий: запрос, падение, перезапуск, исчерпание интенсивности.
%% Запуск: erlc calc_server.erl calc_sup.erl otp_demo.erl
%%         erl -noshell -eval 'otp_demo:main(), halt().'
-module(otp_demo).
-export([main/0]).

%% Сценарий выполняется в отдельном процессе, чтобы trap_exit и связи
%% не затрагивали процесс, в котором erl вычисляет -eval.
main() ->
    {_, Ref} = spawn_monitor(fun run/0),
    receive {'DOWN', Ref, process, _, _} -> ok end.


% --8<-- [start:main]
run() ->
    process_flag(trap_exit, true),              % супервизор связан с нами через start_link
    {ok, Sup} = calc_sup:start_link(),
    io:format("100 div 4 = ~p~n", [calc_server:divide(4)]),
    io:format("handled = ~p~n", [calc_server:handled()]),
    Old = whereis(calc_server),
    crash(),                                    % перезапуск 1
    New = wait_restart(Old),
    io:format("restarted: ~p, handled = ~p~n", [New =/= Old, calc_server:handled()]),
    crash(),                                    % перезапуск 2
    wait_restart(New),
    crash(),                                    % третий за 5 с: больше intensity
    receive {'EXIT', Sup, Reason} -> io:format("supervisor exited: ~p~n", [Reason]) end.

crash() ->
    %% Вызывающий получает исключение exit с причиной падения сервера.
    try calc_server:divide(0) of
        _ -> error(expected_crash)
    catch
        exit:{{Reason, _Stack}, {gen_server, call, _}} ->
            io:format("call failed: ~p~n", [Reason])
    end.
% --8<-- [end:main]

%% Перезапуск асинхронен: ждём, пока имя зарегистрирует новый процесс.
wait_restart(Old) ->
    case whereis(calc_server) of
        Pid when is_pid(Pid), Pid =/= Old -> Pid;
        _ -> timer:sleep(10), wait_restart(Old)
    end.
