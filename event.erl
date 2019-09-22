-module(event).
-compile([debug_info]).




event(Delay)->
    receive
        {cancel}->exit(cancelled)
    after Delay
       exit(ok)
