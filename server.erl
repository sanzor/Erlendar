-module(server).
-compile(export_all).
-record(state,{events,clients}).
-record(event,{name="",
                description="",
                pid,
                timeout={{1970,1,1}{0,0,0}}
).

loop(State)->
    receive 
        {Pid,MsgRef,{subscribe,Client}}->
            Ref=erlang:monitor(process,Client),
            NewClients=orddict:store(Ref,Client,State#state.clients),
            Pid ! {MsgRef,ok},
            loop(S#state{clients=NewClients});

        {Pid,MsgRef,{add,Name,Description,Timeout}}->
            case valid_datetime(Timeout) of 
                true -> 
                    NewEvent=event:start_link(Name,Timeout),
                    NewEvents=orddict:store(Name,
                                            #event{
                                                name=Name,
                                                description=Description,
                                                timeout=Timeout,
                                                pid=NewEvent},
                                            State#state.events),
                    Pid !{MsgRef,ok},
                    loop(State#state{events=NewEvents});
                false ->
                    Pid ! {MsgRef,{error,bad_timeout}},
                    loop(State)
            end;


        {Pid,MsgRef,{cancel,Name}}->
            
            Events=case orddict:find(Name,State#state.events) of ->
                    {ok,Event} -> 
                        cancel(Event#event.pid),
                        orddict:erase(Name,State#state.events);
                    error->
                        State#state.events
                end,
            Pid ! {MsgRef,ok},
            loop(State#{events=Events}).
                
        {done,Name}->
            case orddict:find(Name,State#state.events) of
                {ok,E}->
                    send_to_clients({done,E#event.name,E#event.description},State#state.events),
                    NewEvents=orddict:erase(E,State#state.events),
                    loop(State#state{events=NewEvents}).
                error->
                    loop(State)
            end.
        shutdown->
        {'DOWN',Ref,process,_Pid,_Reason}->
        code_change->
        Unknown->
            io:format("unkown message"),
            loop(State).


send_to_clients(Msg,ClientId)->
    orddict:
valid_datetime({Date,Time})->
    try 
        calendar:valid_date(Date) andalso valid_time(Time)
    catch
        error:function_clause->false;
            
    end;
valid_datetime(_)->false.

valid_time({H,M,S})->valid_time(H,M,S).
valid_time(H,M,S) when  H>=0 && H<24,
                        M>=0 && M<60,
                        S>=0 && S<60 ->true;
valid_time(_,_,_)->false;
init()->
    loop(State#state{events=orddict:new(),clients=orddict:new()}).
            