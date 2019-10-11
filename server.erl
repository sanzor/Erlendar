-module(server).
-compile(export_all).
-record(state,{clients,events}).
-record(event,{
    name="",
    description="",
    pid,
    timeout={{1970,1,1},{0,0,0}}
}).

init()->
    loop(#state{events=orddict:new(),clients=orddict:new()}).

loop(S)->
    receive 

        {Pid,MsgRef,{add,Name,Description,Timeout}}->
            case valid_datetime(Delay) of
                true->
                    EventPid=event:start_link(Name,Timeout),
                    NewEvents=orddict:store(Name,#event{
                        name=Name,
                        description=Description,
                        timeout=Timeout},S#state.events),
                    Pid! {MsgRef,ok},
                    loop(S#state{events=NewEvents});
                false->
                    Pid ! {MsgRef,bad_timeout},
                    loop(S)
            end;
        {Pid,MsgRef,{subscribe,Client}}->
            Ref=erlang:monitor(process,Client),
            NewClients=orddict:store(Ref,Client,S#state.clients),
            Pid !{ MsgRef,ok},
            loop(S#state{clients=NewClients});

        {Pid,MsgRef,{cancel,Name}}->
            Events=case orddict:find(Name,S#state.events) of
                       {ok,E}->
                           event:cancel(E#event.pid),
                           orddict:erase(Name,S#state.events);
                        {error}->
                            S#state.events
                    end
            Pid ! {MsgRef,ok},
            loop(S#state{events=Events});
        {done,Name}->
            case orddict:find(Name,S#state.events) of 
                {ok,E}->
                    send_to_clients({done,E#event.name,E#event.description},S#state.clients),
                    NewEvents=orddict:erase(Name,S#state.events),
                    loop(S#state{events=NewEvents});
                error->
                    loop(S)
            end;
        shutdown->exit(shutdown);
        {'DOWN',MsgRef,process,_Pid,Reason}->
            loop(S#state{clients=orddict:erase(MsgRef,S#state.clients)});
        code_change->
            ?MODULE:loop(S);
        Unknown->io:format("Unknown message"),
                 loop(S)
        end.

send_to_clients(Msg,Clients)->
    orddict:map(fun(Ref,Pid)-> Pid ! Msg ,Clients).
        


valid_datetime({Date,Time}) ->
    try
        calendar:valid_date(Date) andalso valid_time(Time)
    catch
        error:function_clause -> %% not in {{Y,M,D},{H,Min,S}} format
        false
    end;
valid_datetime(_) ->
false.
 
valid_time({H,M,S}) -> valid_time(H,M,S).
valid_time(H,M,S) when H >= 0, H < 24,
                       M >= 0, M < 60,
                       S >= 0, S < 60 -> true;
valid_time(_,_,_) -> false.

start()->
    register(?MODULE,Pid=spawn(?MODULE,init,[])),
    Pid.
start_link()->
    register(?MODULE,Pid=spawn_link(?MODULE,init,[])),
    Pid.

subscribe(Pid)->
    Ref=erlang:monitor(process,Pid),
    ?MODULE ! {self(),Ref,{subscribe,Pid}},
    receive 
        {Ref,ok}->{ok,Ref};
        {'DOWN',Ref,process,_Pid,Reason}->
            {error,Reason}
    after 5000 ->
        {error,timeout}
    end.

add_event(Name,Description,Timeout)->
    Ref=make_ref(),
    ?MODULE ! {self(),Ref,{add,Name,Description,Timeout}},
    receive 
        {Ref,Msg}->Msg
    after 5000 ->
        {error,timeout}
end.

cancel(Name)->
    Ref=make_ref(),
    ?MODULE ! {self(),Ref,{cancel,Name}},
    receive 
        {Ref,ok}->ok
    after 5000->
        {error,timeout}
    end.

    listen(Delay) ->
            receive
            M = {done, _Name, _Description} ->
            [M | listen(0)]
            after Delay*1000 ->
            []
            end.
