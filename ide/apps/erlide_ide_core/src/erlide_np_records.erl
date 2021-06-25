%% Author: jakob
%% Created: 18 dec 2010
-module(erlide_np_records).

%%
%% Include files
%%

-include("erlide_token.hrl").
-include("erlide_search.hrl").

%%
%% Exported Functions
%%
-export([check_fields/2]).

%%
%% API Functions
%%

% check refs to record fields
%

check_fields(Tokens, RecordName) ->
    check_fields(record_name, Tokens, RecordName, [], '', []).

%%
%% Local Functions
%%

check_fields(_State, [], _RecordName, Fields, _PrevRecordName, RightSides) ->
    {[], Fields, lists:reverse(RightSides)};
check_fields(_State, [#token{kind = '}'} | Rest], _RecordName, Fields, _PrevRecordName, RightSides) ->
    {Rest, Fields, lists:reverse(RightSides)};
%% check_fields(_State, [#token{kind=','} | Rest], _RecordName, Fields, '', RightSides) ->
%%     {Rest, Fields, lists:reverse(RightSides)};

% 1
check_fields(_State, [#token{kind = '#'} | Rest], RecordName, Fields, PrevRecordName, RightSides) ->
    check_fields(record_want_name, Rest, RecordName, Fields, PrevRecordName, RightSides);
% 2
check_fields(
    record_want_name,
    [#token{kind = atom, value = NewRecordName} | Rest],
    RecordName,
    Fields,
    _PrevRecordName,
    RightSides
) ->
    check_fields(record_name, Rest, NewRecordName, Fields, RecordName, RightSides);
% 2
check_fields(
    record_want_name,
    [#token{kind = macro, value = NewRecordName} | Rest],
    RecordName,
    Fields,
    _PrevRecordName,
    RightSides
) ->
    check_fields(record_name, Rest, NewRecordName, Fields, RecordName, RightSides);
% 2
check_fields(
    record_want_name, [#token{kind = '?'} | Rest], RecordName, Fields, _PrevRecordName, RightSides
) ->
    check_fields(record_name, Rest, '?', Fields, RecordName, RightSides);
% 3
check_fields(
    record_name, [#token{kind = Dot} | Rest], RecordName, Fields, PrevRecordName, RightSides
) when
    Dot =:= '.'; Dot =:= dot
->
    check_fields(record_want_dot_field, Rest, RecordName, Fields, PrevRecordName, RightSides);
check_fields(
    record_want_dot_field,
    [#token{kind = atom, value = FieldName, offset = Offset, length = Length} | Rest],
    % 4
    RecordName,
    Fields,
    _PrevRecordName,
    RightSides
) ->
    NewFields = [
        {Offset, Length, #record_field_ref{name = FieldName, record = RecordName}} | Fields
    ],
    {Rest, NewFields, lists:reverse(RightSides)};
% 5
check_fields(
    record_name, [#token{kind = '{'} | Rest], RecordName, Fields, PrevRecordName, RightSides
) ->
    check_fields(record_want_field, Rest, RecordName, Fields, PrevRecordName, RightSides);
% 6
check_fields(State, [#token{kind = '{'} | Rest], RecordName, Fields, PrevRecordName, RightSides) ->
    {NewRest, NewFields, NewRS} = check_fields(
        no_record, Rest, RecordName, Fields, PrevRecordName, RightSides
    ),
    check_fields(State, NewRest, RecordName, NewFields, PrevRecordName, lists:reverse(NewRS));
check_fields(
    record_want_field,
    [#token{kind = atom, value = FieldName, offset = Offset, length = Length} | Rest],
    % 7
    RecordName,
    Fields,
    PrevRecordName,
    RightSides
) ->
    NewFields = [
        {Offset, Length, #record_field_ref{name = FieldName, record = RecordName}} | Fields
    ],
    check_fields(record_field, Rest, RecordName, NewFields, PrevRecordName, RightSides);
% 8
check_fields(
    no_record, [#token{kind = ','} | Rest], RecordName, Fields, PrevRecordName, RightSides
) ->
    check_fields(record_want_field, Rest, RecordName, Fields, PrevRecordName, RightSides);
% 9
check_fields(
    record_field, [#token{kind = '='} | Rest], RecordName, Fields, PrevRecordName, RightSides
) ->
    check_fields(no_record, Rest, RecordName, Fields, PrevRecordName, RightSides);
% 10
check_fields(_State, [T | Rest], RecordName, Fields, PrevRecordName, RightSides) ->
    check_fields(no_record, Rest, RecordName, Fields, PrevRecordName, [T | RightSides]).
