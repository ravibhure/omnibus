%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosPropertyService_PropertyMode
%% Source: /net/isildur/ldisk/daily_build/otp_prebuild_r14b.2010-09-13_19/otp_src_R14B/lib/cosProperty/src/CosProperty.idl
%% IC vsn: 4.2.25
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosPropertyService_PropertyMode').
-ic_compiled("4_2_25").


-include("CosPropertyService.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_struct,"IDL:omg.org/CosPropertyService/PropertyMode:1.0",
                   "PropertyMode",
                   [{"property_name",{tk_string,0}},
                    {"property_mode",
                     {tk_enum,"IDL:omg.org/CosPropertyService/PropertyModeType:1.0",
                              "PropertyModeType",
                              ["normal","read_only","fixed_normal",
                               "fixed_readonly","undefined"]}}]}.

%% returns id
id() -> "IDL:omg.org/CosPropertyService/PropertyMode:1.0".

%% returns name
name() -> "CosPropertyService_PropertyMode".



