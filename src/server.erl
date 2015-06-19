-module(server).
-behaviour (gen_server).


%% server: server library's entry point.

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2, handle_info/2, stop/1]).
-export([get_script/2,save_script/3]).

start_link()->
	gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([])->
	Tab = ets:new(?MODULE,[named_table, public, set]),
	Timer = erlang:send_after(1, self(), check),
	{ok, {Tab,Timer}}.

stop(_Pid)->
	stop().
	
stop()->
	gen_server:cast(?MODULE, stop).

handle_call({add_rec,Index, Value}, _From, Rec) ->
	ets:insert(Rec,{Index, Value, time = calendar:local_time()}),
	Reply = ok,
	{reply, Reply, Rec};

handle_call({update_rec,Index, Value}, _From, Rec) ->
	ets:insert(Rec,{Index, Value, time = calendar:local_time()}),
	Reply = ok,
	{reply, Reply, Rec};

handle_call({lookup_index,InIndex, Value}, _From, Rec) ->
	T = ets:fun2ms(fun({Index, Value, time})
		when Index == InIndex ->
			[Value] end),
	Reply = {ok, ets:select(Rec, T)},
	{reply, Reply, Rec};

handle_call({lookup_time,Time1, Time2}, _From, Rec) ->
	T = ets:fun2ms(fun({Index, Value, time})
		when time >= Time1 andalso time =< Time2 ->
		[Value],end),
	ets:insert(Rec,{Index, Value, time = calendar:local_time()}),
	Reply = {ok, ets:select(Rec, T)},
	{reply, Reply, Rec};

handle_call({del_rec,Index}, _From, Rec) ->
	ets:delete(Rec,Index),
	Reply = ok,
	{reply, Reply, Rec}.

handle_call(stop, _From, Rec) ->
    {stop, normal, stopped, Rec}.

handle_cast(_Msg, State) -> 
    {noreply, State}.

handle_info(_Info, {Tab,Timer}) -> 
	Timer = erlang:send_after(1000, self()),
    {noreply, {Tab,Timer}}.

terminate(_Reason, _State) -> 
    ok.

code_change(_OldVsn, State, Extra) -> 
    {ok, State}.

insert(Index, Value) ->
    gen_server:call(?MODULE, {add_rec, Index, Value}).

update(Index, Value) ->
    gen_server:call(?MODULE, {update_rec, Index, Value}).

delete(Index) ->
    gen_server:call(?MODULE, {del_rec, Index}).

lookup(Index) ->
    gen_server:call(?MODULE, {lookup_index, Index}).

lookup_by_date(DateFrom, DateTo) ->
    gen_server:call(?MODULE, {lookup_time, Time1, Time2}).