simplest_one_for_one
====================

A bit simpler than simple_one_for_one.

By doing `{ok, Sup} = simplest_one_for_one:start_link( {local, SupRegName}, { WorkerMod, WorkerStartLinkFunc, WorkerFixedArgs } ).` you just spawn_link something pretty much alike to the simple_one_for_one supervisor, but slightly simpler.

This implementation of supervisor handles the sampe gen-calls as the traditional supervisor does, hence you spawn worker using `supervisor:start_child/2` and terminate them with `supervisor:terminate_child/2`.

