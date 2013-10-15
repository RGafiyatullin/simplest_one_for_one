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

-module (simplest_one_for_one).
-behaviour (gen_server).
-export([
		start_link/1,
		start_link/2,
		start_link/3
	]).
-export([
		init/1,
		handle_call/3,
		handle_cast/2,
		handle_info/2,
		terminate/2,
		code_change/3
	]).

-record(args, {
		mfa :: { Module :: atom(), Function :: atom(), Args :: [term()] }
	}).

start_link( MFA = {M, F, A} )
	when is_atom( M )
	andalso is_atom(F)
	andalso is_list( A )
-> 
	gen_server:start_link( ?MODULE, #args{ mfa = MFA }, [] ).

start_link( MFA = {M, F, A}, GenServerOpts )
	when is_atom( M )
	andalso is_atom(F)
	andalso is_list( A )
	andalso is_list( GenServerOpts )
->
	gen_server:start_link( ?MODULE, #args{ mfa = MFA }, GenServerOpts ).

start_link( RegName, MFA = {M, F, A}, GenServerOpts )
	when is_atom( M )
	andalso is_atom(F)
	andalso is_list( A )
	andalso is_list( GenServerOpts )
->
	gen_server:start_link( RegName, ?MODULE, #args{ mfa = MFA }, GenServerOpts ).

%%% %%%%%%%%%% %%%
%%% gen_server %%%
%%% %%%%%%%%%% %%%

-record(s, {
		mfa :: mfa()
	}).
-type state() :: #s{}.

init(#args{
		mfa = MFA
	}) -> 
		false = erlang:process_flag( trap_exit, true ),
		{ok, #s{
			mfa = MFA
		}}.
handle_call( {start_child, MoreArgs}, _From, State = #s{} ) -> do_handle_call_start_child( MoreArgs, State );
handle_call( {terminate_child, Pid}, _From, State = #s{} ) -> do_handle_call_terminate_child( Pid, State );
handle_call( which_children, _From, State = #s{} ) -> do_handle_call_which_children( State );
handle_call(Request, _From, State = #s{}) -> error_logger:warning_report([?MODULE, handle_call, {badarg, Request}]), {reply, {badarg, Request}, State}.
handle_cast(Request, State = #s{}) -> error_logger:warning_report([?MODULE, handle_cast, {badarg, Request}]), {noreply, State}.
handle_info({'EXIT', Pid, Reason}, State = #s{}) -> do_handle_info_exit( Pid, Reason, State );
handle_info(Request, State = #s{}) -> error_logger:warning_report([?MODULE, handle_info, {badarg, Request}]), {noreply, State}.
terminate(_Reason, _State) -> ignore.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%% %%%%%%%% %%%
%%% Internal %%%
%%% %%%%%%%% %%%
-type start_child_reply() :: {ok, pid()} | {ok, pid(), term()} | {ok, undefined} | {error, term()}.
-spec do_handle_call_start_child( [term()], state() ) -> {reply, start_child_reply(), state()}.
do_handle_call_start_child( MoreArgs, State = #s{ mfa = {M, F, Args} } ) ->
	case catch erlang:apply( M, F, Args ++ MoreArgs ) of
		{ok, Pid} when is_pid( Pid ) -> {reply, {ok, Pid}, register_child( Pid, State )};
		{ok, Pid, Something} when is_pid( Pid ) -> {reply, {ok, Pid, Something}, register_child( Pid, State ) };
		ignore -> {reply, {ok, undefined}, State};
		{error, Error} -> {reply, {error, Error}, State};
		Wat -> {reply, {error, Wat}, State}
	end.

-type terminate_child_reply() :: ok | {error, not_found}.
-spec do_handle_call_terminate_child( pid(), state() ) -> {reply, terminate_child_reply(), state()}.
do_handle_call_terminate_child( Pid, State ) ->
	case is_registered( Pid, State ) of
		false -> {reply, {error, not_found}, State};
		true ->
			erlang:exit( Pid, kill ),
			{reply, ok, State}
	end.

-spec do_handle_info_exit( pid(), term(), state() ) -> {noreply, state()}.
do_handle_info_exit( Pid, Reason, StateIn ) ->
	case unregister_child( Pid, StateIn ) of
		{true, StateOut} -> {noreply, StateOut};
		{false, StateOut} ->
			error_logger:warning_report([?MODULE,
				unexpected_exit_msg, {pid, Pid}, {reason, Reason}]),
			{noreply, StateOut}
	end.

-spec is_registered( pid(), state() ) -> boolean().
is_registered( Pid, _State ) ->
	case erlang:get( {child, Pid} ) of
		{?MODULE, true} -> true;
		_ -> false
	end.

-spec register_child( pid(), state() ) -> state().
register_child( Pid, State ) ->
	undefined = erlang:put( {child, Pid}, {?MODULE, true} ),
	State.

-spec unregister_child( pid(), state() ) -> {boolean(), state()}.
unregister_child( Pid, State ) ->
	case erlang:erase( {child, Pid} ) of
		{?MODULE, true} -> {true, State};
		undefined -> {false, State};
		Junk ->
			error_logger:warning_report([?MODULE, unregister_child,
				{junk_in_pd_entry, Junk}, {child, Pid}]),
			{false, State}
	end.

-type which_children() :: [ {undefined, pid(), worker, [ atom() ]} ].
-spec do_handle_call_which_children( state() ) -> {reply, which_children(), state()}.
do_handle_call_which_children( State = #s{ mfa = {Mod, _, _} } ) ->
	WhichChildren = [ {undefined, ChildPid, worker, [ Mod ]} || {{child, ChildPid}, {?MODULE, true}} <- erlang:get() ],
	{reply, WhichChildren, State}.
