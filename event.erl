*-module(event).
-compile([debug_info]).
-export([loop/1]).

-record(state,
 {server,
  name="",
  to_go=0
}).

normalize(N)->
        Limit = 49*24*60*60,
        [N rem Limit | lists:duplicate(N div Limit,Limit)]

start(EventName,Delay)->
    spawn(?MODULE,init,[self(),EventName,Delay]).

start_link(EventName,Delay)->
        spawn_link(?MODULE,init,[self(),EventName,Delay]).

cancel(EventName)->
    
init(Server,EventName,Delay)->
    loop(#state{
                server=Server,
                name=EventName,
                to_go=normalize(Delay)}
        ).

loop(S=#state{server=Server,to_go=[T|Next]})->
    receive
        {Server,Ref,cancel}->
            Server ! {Ref , ok}
    after T*1000->
        if Next =:= [] ->
            Server ! {done,S#state.name};
           Next =/= [] ->
               loop(S#state{to_go=Next})
end.


