%% OTP-супервизор: одна спецификация дочернего процесса.
-module(calc_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

% --8<-- [start:init]
init([]) ->
    SupFlags = #{strategy  => one_for_one,   % перезапускать только упавшего
                 intensity => 2,             % не больше 2 перезапусков…
                 period    => 5},            % …за 5 секунд, иначе упасть самому
    Child = #{id       => calc_server,
              start    => {calc_server, start_link, []},
              restart  => permanent,         % перезапускать при любом завершении
              shutdown => 1000,              % мс на корректную остановку
              type     => worker,
              modules  => [calc_server]},
    {ok, {SupFlags, [Child]}}.
% --8<-- [end:init]
