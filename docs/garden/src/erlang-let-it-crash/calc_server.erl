%% gen_server со счётчиком обработанных запросов (состояние процесса).
-module(calc_server).
-behaviour(gen_server).

-export([start_link/0, divide/1, handled/0]).
-export([init/1, handle_call/3, handle_cast/2]).

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

divide(X) -> gen_server:call(?MODULE, {divide, X}).
handled() -> gen_server:call(?MODULE, handled).

% --8<-- [start:callbacks]
init([]) -> {ok, 0}.

handle_call({divide, X}, _From, N) -> {reply, 100 div X, N + 1};   % X = 0 -> badarith
handle_call(handled, _From, N)     -> {reply, N, N}.
% --8<-- [end:callbacks]

handle_cast(_Msg, N) -> {noreply, N}.
