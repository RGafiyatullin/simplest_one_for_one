% Copyright 2013 and onwards Roman Gafiyatullin
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
% 
% See the NOTICE file distributed with this work for additional information regarding copyright ownership.
% 

-module (simplest_one_for_one_example).
-export ([
	test/0,
	start_link/0,
	start_link_srv/1,
	init_srv/1
	]).

test() ->
	Ret0 = start_link(),
	Ret1 = supervisor:start_child( ?MODULE, [ fun() -> io:format("F1~n") end ] ),
	Ret2 = supervisor:start_child( ?MODULE, [ fun() -> io:format("F2~n") end ] ),
	Ret3 = supervisor:start_child( ?MODULE, [ fun() -> io:format("F3~n") end ] ),
	{ [Ret0, Ret1, Ret2, Ret3],  supervisor:which_children( ?MODULE ) }.

start_link() -> simplest_one_for_one:start_link( {local, ?MODULE}, {?MODULE, start_link_srv, []} ).

start_link_srv( F ) -> proc_lib:start_link( ?MODULE, init_srv, [ F ] ).
init_srv( F ) ->
	proc_lib:init_ack( {ok, self()} ),
	timer:sleep(1000),
	Ret = F(),
	io:format("F() -> ~p~n", [Ret]),
	timer:sleep(10000).

