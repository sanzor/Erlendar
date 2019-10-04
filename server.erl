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
        {Pid,MsgRef,{cancel,Name}}->
        {done,Name}->
        shutdown->
        {'DOWN',Ref,process,_Pid,_Reason}->
        code_change->
        Unknown->
            io:format("unkown message"),
            loop(State).
init()->
    loop(State#state{events=orddict:new(),clients=orddict:new()}).
            