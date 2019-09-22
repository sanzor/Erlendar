-module(event).
-compile([debug_info]).
-export([event/1]).

-record(state,{server,
               name="",
               to_go=0}).



event(S=#state{server=Server})->
    receive
        {Server,Ref,cancel}->
            Server ! {Ref,ok}
    after S#state.to_go*1000 ->
        Server ! {done,S#state.name}
end.
