%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2005-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%
%%
-module(httpc_cookie_SUITE).

-include("test_server.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% Test server specific exports
-export([all/1, init_per_testcase/2, end_per_testcase/2]).

%% Test cases must be exported.
-export([session_cookies_only/1, netscape_cookies/1, 
	 cookie_cancel/1, cookie_expires/1, persistent_cookie/1,
	 domain_cookie/1, secure_cookie/1, update_cookie/1, 
	 update_cookie_session/1, cookie_attributes/1]).

-define(URL,        "http://myhost.cookie.test.org").
-define(URL_DOMAIN, "http://myhost2.cookie.test.org").
-define(URL_SECURE, "https://myhost.cookie.test.org").

%% Test server callback functions

%%--------------------------------------------------------------------
%% Function: init_per_testcase(TestCase, Config) -> Config
%% Case - atom()
%%   Name of the test case that is about to be run.
%% Config - [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%%
%% Description: Initiation before each test case
%%
%% Note: This function is free to add any key/value pairs to the Config
%% variable, but should NOT alter/remove any existing entries.
%% Description: Initiation before each test case
%%--------------------------------------------------------------------
init_per_testcase(session_cookies_only = Case, Config0) ->
    tsp("init_per_testcase(~p) -> entry with"
	"~n   Config0: ~p", [Case, Config0]),
    Config = init_workdir(Case, Config0), 
    application:start(inets), 
    http:set_options([{cookies, verify}]),
    watch_dog(Config);

init_per_testcase(Case, Config0) ->
    tsp("init_per_testcase(~p) -> entry with"
	"~n   Config0: ~p", [Case, Config0]),
    Config = init_workdir(Case, Config0), 
    CaseDir = ?config(case_top_dir, Config),
    application:load(inets),
    application:set_env(inets, services, [{httpc, {default, CaseDir}}]),
    application:start(inets), 
    http:set_options([{cookies, verify}]),
    watch_dog(Config).

watch_dog(Config) ->
    Dog = test_server:timetrap(inets_test_lib:minutes(10)),
    NewConfig = lists:keydelete(watchdog, 1, Config),
    [{watchdog, Dog} | NewConfig].

init_workdir(Case, Config) ->
    PrivDir = ?config(priv_dir, Config),
    SuiteTopDir = filename:join(PrivDir, ?MODULE),
    case file:make_dir(SuiteTopDir) of
        ok ->
            ok;
        {error, eexist} ->
            ok;
        Error ->
            tsf({failed_creating_subsuite_top_dir, Error})
    end,

    CaseTopDir = filename:join(SuiteTopDir, Case),
    ?line ok   = file:make_dir(CaseTopDir),
    [{suite_top_dir, SuiteTopDir}, 
     {case_top_dir,  CaseTopDir} | Config].


%%--------------------------------------------------------------------
%% Function: end_per_testcase(TestCase, Config) -> _
%% Case - atom()
%%   Name of the test case that is about to be run.
%% Config - [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%% Description: Cleanup after each test case
%%--------------------------------------------------------------------
end_per_testcase(Case, Config) ->
    tsp("end_per_testcase(~p) -> entry with"
	"~n   Config: ~p", [Case, Config]),
    application:stop(inets),
    Dog = ?config(watchdog, Config),
    test_server:timetrap_cancel(Dog),
    ok.

%%--------------------------------------------------------------------
%% Function: all(Clause) -> TestCases
%% Clause - atom() - suite | doc
%% TestCases - [Case] 
%% Case - atom()
%%   Name of a test case.
%% Description: Returns a list of all test cases in this test suite
%%--------------------------------------------------------------------
all(doc) -> 
    ["Describe the main purpose of this suite"];

all(suite) -> 
    [
     session_cookies_only, 
     netscape_cookies, 
     cookie_cancel,
     cookie_expires, 
     persistent_cookie, 
     domain_cookie, 
     secure_cookie,
     update_cookie, 
     update_cookie_session, 
     cookie_attributes
    ].

%% Test cases starts here.
%%--------------------------------------------------------------------
session_cookies_only(doc) -> 
    ["Test that all cookies are handled as session cookies if there"
     "does not exist a directory to save presitent cookies in."];
session_cookies_only(suite) -> 
    [];
session_cookies_only(Config) when is_list(Config) -> 
    tsp("session_cookies_only -> Cookies 1: ~p", [httpc:which_cookies()]),

    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			 ";max-age=60000"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
     {"cookie","$Version=0; test_cookie=true; $Path=/"}
	= http:cookie_header(?URL),
    application:stop(inets),
    application:start(inets),
    {"cookie",""} = http:cookie_header(?URL),

    tsp("session_cookies_only -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.

netscape_cookies(doc) -> 
    ["Test that the old (original) format of cookies are accepted."];
netscape_cookies(suite) -> 
    [];
netscape_cookies(Config) when is_list(Config) -> 
    tsp("netscape_cookies -> Cookies 1: ~p", [httpc:which_cookies()]),

    Expires = future_netscape_date(),
    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/; " 
			 "expires=" ++ Expires}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=0; test_cookie=true; $Path=/"} = 
	http:cookie_header(?URL),

    tsp("netscape_cookies -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.

cookie_cancel(doc) -> 
    ["A cookie can be canceld by sending the same cookie with max-age=0 "
     "this test cheks that cookie is canceled."];
cookie_cancel(suite) -> 
    [];
cookie_cancel(Config) when is_list(Config) -> 
    tsp("cookie_cancel -> Cookies 1: ~p", [httpc:which_cookies()]),

    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			 "max-age=60000"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=0; test_cookie=true; $Path=/"}
	= http:cookie_header(?URL),
    NewSetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			    "max-age=0"}],
    http:verify_cookies(NewSetCookieHeaders, ?URL),
    {"cookie", ""} = http:cookie_header(?URL),

    tsp("cookie_cancel -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.

cookie_expires(doc) -> 
    ["Test that a cookie is not used when it has expired"];
cookie_expires(suite) -> 
    [];
cookie_expires(Config) when is_list(Config) -> 
    tsp("cookie_expires -> Cookies 1: ~p", [httpc:which_cookies()]),

    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			 "max-age=5"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=0; test_cookie=true; $Path=/"}
	= http:cookie_header(?URL),
    test_server:sleep(10000),
    {"cookie", ""} = http:cookie_header(?URL),

    tsp("cookie_expires -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.

persistent_cookie(doc) ->
    ["Test domian cookie attribute"];
persistent_cookie(suite) ->
    [];
persistent_cookie(Config) when is_list(Config)->
    tsp("persistent_cookie -> Cookies 1: ~p", [httpc:which_cookies()]),

    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			 "max-age=60000"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=0; test_cookie=true; $Path=/"} = 
	http:cookie_header(?URL),
    CaseDir = ?config(case_top_dir, Config),
    application:stop(inets),
    application:load(inets),
    application:set_env(inets, services, [{httpc, {default, CaseDir}}]),
    application:start(inets), 
    http:set_options([{cookies, enabled}]),
    {"cookie","$Version=0; test_cookie=true; $Path=/"} = http:cookie_header(?URL),

    tsp("persistent_cookie -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.


domain_cookie(doc) ->
    ["Test the domian cookie attribute"];
domain_cookie(suite) ->
    [];
domain_cookie(Config) when is_list(Config) ->
    tsp("domain_cookie -> Cookies 1: ~p", [httpc:which_cookies()]),

    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;" 
			 "domain=.cookie.test.org"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=0; test_cookie=true; $Path=/; "
     "$Domain=.cookie.test.org"} = 
	http:cookie_header(?URL_DOMAIN),

    tsp("domain_cookie -> Cookies 2: ~p", [httpc:which_cookies()]),
    ok.


secure_cookie(doc) ->
    ["Test the secure cookie attribute"];
secure_cookie(suite) ->
    [];
secure_cookie(Config) when is_list(Config) ->
    tsp("secure_cookie -> entry with"
	"~n   Config: ~p", [Config]),
    
    inets:enable_trace(max, io, httpc),

    %% httpc:reset_cookies(), 

    tsp("secure_cookie -> Cookies 1: ~p", [httpc:which_cookies()]),
    
    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/; secure"}],
    tsp("secure_cookie -> verify cookies (1)"),
    ok = http:verify_cookies(SetCookieHeaders, ?URL),

    tsp("secure_cookie -> Cookies 2: ~p", [httpc:which_cookies()]),

    tsp("secure_cookie -> check cookie (secure)"),
    check_cookie("$Version=0; test_cookie=true; $Path=/", ?URL_SECURE), 
	
    tsp("secure_cookie -> check cookie (plain)"),
    check_cookie("", ?URL),

    tsp("secure_cookie -> verify cookies (2)"),
    SetCookieHeaders1 = [{"set-cookie", "test1_cookie=true; path=/; secure"}],
    ok = http:verify_cookies(SetCookieHeaders1, ?URL),

    tsp("secure_cookie -> Cookies 3: ~p", [httpc:which_cookies()]),

    tsp("secure_cookie -> cookie header (3)"),
    check_cookie("$Version=0; test_cookie=true; $Path=/; "
		 "test1_cookie=true; $Path=/",
		 ?URL_SECURE), 
%%     {"cookie","$Version=0; test_cookie=true; $Path=/; "
%%      "test1_cookie=true; $Path=/"} = http:cookie_header(?URL_SECURE),

    tsp("secure_cookie -> Cookies 4: ~p", [httpc:which_cookies()]),

    inets:disable_trace(),
    tsp("secure_cookie -> done"),
    ok.
    
update_cookie(doc)->
    ["Test that a cookie can be updated."];
update_cookie(suite) ->
    [];
update_cookie(Config) when is_list(Config)->
    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/;"
			 "max-age=6500"},
			{"set-cookie", "test_cookie2=true; path=/;"
			 "max-age=6500"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie", "$Version=0; test_cookie2=true; $Path=/; "
     "test_cookie=true; $Path=/"} = http:cookie_header(?URL),
    NewSetCookieHeaders = [{"set-cookie", "test_cookie=false; "
			    "path=/;max-age=6500"}],
    http:verify_cookies(NewSetCookieHeaders, ?URL),
    {"cookie", "$Version=0; test_cookie2=true; $Path=/; "
     "test_cookie=false; $Path=/"} = http:cookie_header(?URL).
    
update_cookie_session(doc)->
    ["Test that a cookie can be updated."];
update_cookie_session(suite) ->
    [];
update_cookie_session(Config) when is_list(Config)->
    SetCookieHeaders = [{"set-cookie", "test_cookie=true; path=/"},
			{"set-cookie", "test_cookie2=true; path=/"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie", "$Version=0; test_cookie2=true; $Path=/; "
     "test_cookie=true; $Path=/"} = http:cookie_header(?URL),
    NewSetCookieHeaders = [{"set-cookie", "test_cookie=false; path=/"}],
    http:verify_cookies(NewSetCookieHeaders, ?URL),
    {"cookie", "$Version=0; test_cookie2=true; $Path=/; "
     "test_cookie=false; $Path=/"} = http:cookie_header(?URL).
    

cookie_attributes(doc) -> 
    ["Test attribute not covered by the other test cases"];
cookie_attributes(suite) -> 
    [];
cookie_attributes(Config) when is_list(Config) -> 
    SetCookieHeaders = [{"set-cookie", "test_cookie=true;version=1;"
			 "comment=foobar; "%% Comment
			 "foo=bar;" %% Nonsense should be ignored
			 "max-age=60000"}],
    http:verify_cookies(SetCookieHeaders, ?URL),
    {"cookie","$Version=1; test_cookie=true"} = http:cookie_header(?URL),
    ok.


%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

check_cookie(Expect, URL) ->
    case http:cookie_header(URL) of
	{"cookie", Expect} ->
	    ok;
	{"cookie", Unexpected} ->
	    case lists:prefix(Expect, Unexpected) of
		true ->
		    Extra = Unexpected -- Expect, 
		    tsf({extra_cookie_info, Extra});
		false ->
		    tsf({unknown_cookie, Expect, Unexpected})
	    end;
	Bad ->
	    tsf({bad_cookies, Bad})
    end.


future_netscape_date() ->
    [Day, DD, Mon, YYYY] = netscape_date(date()),
    lists:flatten(io_lib:format("~s, ~s ~s ~s 12:30:00 GMT", 
				[Day, DD, Mon, YYYY])).

netscape_date({Year, 12, _}) ->
    NewYear = Year + 1,
    NewMonth = 1,
    NewDay = calendar:last_day_of_the_month(NewYear, NewMonth),
    WeekDay = calendar:day_of_the_week(NewYear, NewMonth, NewDay),
    WeekDayNrStr = day_nr_str(NewDay), 
    NewDayStr = week_day_str(WeekDay),
    MonthStr = month_str(NewMonth),
    [NewDayStr, WeekDayNrStr, MonthStr, integer_to_list(NewYear)];

netscape_date({Year, Month, _})  ->
    NewMonth = Month + 1,
    NewDay = calendar:last_day_of_the_month(Year, NewMonth),
    WeekDay = calendar:day_of_the_week(Year, NewMonth, NewDay),
    WeekDayNrStr = day_nr_str(NewDay), 
    NewDayStr = week_day_str(WeekDay),
    MonthStr = month_str(NewMonth),
    [NewDayStr, WeekDayNrStr, MonthStr, integer_to_list(Year)].

week_day_str(1) ->
    "Mon";
week_day_str(2) ->
    "Tus";
week_day_str(3) ->
    "Wdy";
week_day_str(4) ->
    "Thu";
week_day_str(5) ->
    "Fri";
week_day_str(6) ->
    "Sat";
week_day_str(7) ->
    "Sun".

day_nr_str(1) ->
    "01";
day_nr_str(2) ->
    "02";
day_nr_str(3) ->
    "03";
day_nr_str(4) ->
    "04";
day_nr_str(5) ->
    "05";
day_nr_str(6) ->
    "06";
day_nr_str(7) ->
    "07";
day_nr_str(8) ->
    "08";
day_nr_str(0) ->
    "09";
day_nr_str(N) ->
    integer_to_list(N).

month_str(1) ->"Jan";
month_str(2) ->"Feb";
month_str(3) ->"Mar"; 
month_str(4) ->"Apr";
month_str(5) ->"May";
month_str(6) ->"Jun";
month_str(7) ->"Jul";
month_str(8) ->"Aug";
month_str(9) ->"Sep";
month_str(10) ->"Oct";
month_str(11) ->"Nov";
month_str(12) ->"Dec".


tsp(F) ->
    tsp(F, []).
tsp(F, A) ->
    test_server:format("~p ~p:" ++ F ++ "~n", [self(), ?MODULE | A]).

tsf(Reason) ->
    test_server:fail(Reason).

