-module(upgrade).
-export([main/1,upgrade/1]).
-record(state,{ version=0,comments=""}).


init(State)->
    spawn(?MODULE,main,[State]).
init_link(State)->
    spawn_link(?MODULE,main,[State]).
main(State)->
    receive 
        update->
            NewState=?MODULE:upgrade(State),
            ?MODULE:main(NewState);
        SomeMessage->
            main(State)
    end.

upgrade(State=#state{version=Version,comments=Comments})->
    Comm=case Version rem 2 of
            0 -> "Even version";
            _ -> "Uneven version"
         end,
    #state{version=Version+1,comments=Comm}.