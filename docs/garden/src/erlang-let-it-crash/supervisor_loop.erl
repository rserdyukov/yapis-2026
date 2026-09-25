%% Супервизор, написанный вручную: trap_exit + spawn_link + перезапуск.
%% Запуск: erlc supervisor_loop.erl && erl -noshell -eval 'supervisor_loop:main(), halt().'
-module(supervisor_loop).
-export([main/0]).

-define(MAX_RESTARTS, 3).

%% Сценарий выполняется в отдельном процессе, чтобы trap_exit и связи
%% не затрагивали процесс, в котором erl вычисляет -eval.
main() ->
    {_, Ref} = spawn_monitor(fun run/0),
    receive {'DOWN', Ref, process, _, _} -> ok end.


% --8<-- [start:worker]
start_worker() ->
    spawn_link(fun() -> worker(0) end).

%% Рабочий знает только «счастливый путь»; Handled — его состояние.
worker(Handled) ->
    receive
        {job, From, X} ->
            From ! {done, self(), 100 div X, Handled + 1},   % X = 0 -> badarith
            worker(Handled + 1)
    end.
% --8<-- [end:worker]

run() ->
    process_flag(trap_exit, true),
    supervise([4, 1, 0, 5, 0, 2], start_worker(), 0).

% --8<-- [start:supervise]
supervise([], _Worker, Restarts) ->
    io:format("done: restarts = ~p~n", [Restarts]);
supervise([X | Rest], Worker, Restarts) ->
    Worker ! {job, self(), X},
    receive
        {done, Worker, Result, Handled} ->
            io:format("job ~p -> ~p (handled by this worker: ~p)~n", [X, Result, Handled]),
            supervise(Rest, Worker, Restarts);
        {'EXIT', Worker, {Reason, _Stack}} when Restarts < ?MAX_RESTARTS ->
            io:format("job ~p: worker crashed: ~p; restart ~p~n", [X, Reason, Restarts + 1]),
            supervise(Rest, start_worker(), Restarts + 1);
        {'EXIT', Worker, _Reason} ->
            io:format("job ~p: too many restarts, giving up~n", [X]),
            {error, too_many_restarts}
    end.
% --8<-- [end:supervise]
