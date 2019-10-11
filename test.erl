-module(test).
-export([doo/0,loop/0]).

doo()->
    spawn(?MODULE,loop,[]).

loop()->
    receive 
        Msg-> ?MODULE ! "got message",
              loop()
end.