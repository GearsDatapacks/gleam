-define(is_lowercase_char(X), (X > 96 andalso X < 123)).
-define(is_underscore_char(X), (X == 95)).
-define(is_digit_char(X), (X > 47 andalso X < 58)).
-define(could_be_record(Tuple),
    is_tuple(Tuple) andalso
        is_atom(element(1, Tuple)) andalso
        element(1, Tuple) =/= false andalso
        element(1, Tuple) =/= true andalso
        element(1, Tuple) =/= nil
).
-define(is_atom_char(C),
    (?is_lowercase_char(C) orelse
        ?is_underscore_char(C) orelse
        ?is_digit_char(C))
).

echo(Value) ->
    String = echo@inspect(Value),
    io:put_chars(standard_error, [String, $\n]),
    Value.

echo@inspect(Value) ->
    case Value of
        nil -> "Nil";
        true -> "True";
        false -> "False";
        Int when is_integer(Int) -> erlang:integer_to_list(Int);
        Float when is_float(Float) -> io_lib_format:fwrite_g(Float);
        Bits when is_bitstring(Bits) -> inspect@bit_array(Bits);
        Binary when is_binary(Binary) -> inspect@binary(Binary);
        Atom when is_atom(Atom) -> inspect@atom(Atom);
        List when is_list(List) -> inspect@list(List);
        Map when is_map(Map) -> inspect@map(Map);
        Record when ?could_be_record(Record) -> inspect@record(Record);
        Tuple when is_tuple(Tuple) -> inspect@tuple(Tuple);
        Function when is_function(Function) -> inspect@function(Function);
        Any -> ["//erl(", io_lib:format("~p", [Any]), ")"]
    end.

inspect@bit_array(Bits) ->
    Pieces = inspect@bit_array_pieces(Bits, []),
    Inner = string:join(lists:reverse(Pieces), <<", ">>),
    <<"<<", Inner/binary, ">>">>.

inspect@bit_array_pieces(Bits, Acc) ->
    case Bits of
        <<>> ->
            Acc;
        <<Byte, Rest/bitstring>> ->
            inspect@bit_array_pieces(Rest, [integer_to_binary(Byte) | Acc]);
        _ ->
            Size = bit_size(Bits),
            <<RemainingBits:Size>> = Bits,
            SizeString = <<":size(", (integer_to_binary(Size)), ")">>,
            Piece = <<(integer_to_binary(RemainingBits)), SizeString>>,
            inspect@bit_array_pieces(<<>>, [Piece | Acc])
    end.

inspect@binary(Binary) ->
    case inspect@maybe_utf8_string(Binary, <<>>) of
        {ok, InspectedUtf8String} ->
            InspectedUtf8String;
        {error, not_a_utf8_string} ->
            Segments = [integer_to_list(X) || <<X>> <= Binary],
            ["<<", lists:join(", ", Segments), ">>"]
    end.

inspect@atom(Atom) ->
    Binary = erlang:atom_to_binary(Atom),
    case inspect@maybe_gleam_atom(Binary, none, <<>>) of
        {ok, Inspected} -> Inspected;
        {error, _} -> ["atom.create_from_string(\"", Binary, "\")"]
    end.

inspect@list(List) ->
    case inspect@proper_or_improper_list(List) of
        {proper, Elements} -> ["[", Elements, "]"];
        {improper, Elements} -> ["//erl([", Elements, "])"]
    end.

inspect@map(Map) ->
    Fields = [
        [<<"#(">>, echo@inspect(Key), <<", ">>, echo@inspect(Value), <<")">>]
     || {Key, Value} <- maps:to_list(Map)
    ],
    ["dict.from_list([", lists:join(", ", Fields), "])"].

inspect@record(Record) ->
    [Atom | ArgsList] = erlang:tuple_to_list(Record),
    Args = lists:join(", ", lists:map(fun echo@inspect/1, ArgsList)),
    [echo@inspect(Atom), "(", Args, ")"].

inspect@tuple(Tuple) ->
    Elements = lists:map(fun echo@inspect/1, erlang:tuple_to_list(Tuple)),
    ["#(", lists:join(", ", Elements), ")"].

inspect@function(Function) ->
    {arity, Arity} = erlang:fun_info(Function, arity),
    ArgsAsciiCodes = lists:seq($a, $a + Arity - 1),
    Args = lists:join(", ", lists:map(fun(Arg) -> <<Arg>> end, ArgsAsciiCodes)),
    ["//fn(", Args, ") { ... }"].

inspect@maybe_utf8_string(Binary, Acc) ->
    case Binary of
        <<>> ->
            {ok, <<$", Acc/binary, $">>};
        <<First/utf8, Rest/binary>> ->
            Escaped = inspect@escape_grapheme(First),
            inspect@maybe_utf8_string(Rest, <<Acc/binary, Escaped/binary>>);
        _ ->
            {error, not_a_utf8_string}
    end.

inspect@escape_grapheme(Char) ->
    case Char of
        $" -> <<$\\, $">>;
        $\\ -> <<$\\, $\\>>;
        $\r -> <<$\\, $r>>;
        $\n -> <<$\\, $n>>;
        $\t -> <<$\\, $t>>;
        $\f -> <<$\\, $f>>;
        X when X > 126, X < 160 -> inspect@convert_to_u(X);
        X when X < 32 -> inspect@convert_to_u(X);
        Other -> <<Other/utf8>>
    end.

inspect@convert_to_u(Code) ->
    list_to_binary(io_lib:format("\\u{~4.16.0B}", [Code])).

inspect@proper_or_improper_list(List) ->
    case List of
        [] ->
            {proper, []};
        [First] ->
            {proper, [echo@inspect(First)]};
        [First | Rest] when is_list(Rest) ->
            {Kind, Inspected} = inspect@list(Rest),
            {Kind, [echo@inspect(First), ", " | Inspected]};
        [First | ImproperRest] ->
            {improper, [echo@inspect(First), " | ", echo@inspect(ImproperRest)]}
    end.

inspect@maybe_gleam_atom(Atom, PrevChar, Acc) ->
    case {Atom, PrevChar} of
        {<<>>, none} ->
            {error, nil};
        {<<First, _/binary>>, none} when ?is_digit_char(First) ->
            {error, nil};
        {<<"_", _/binary>>, none} ->
            {error, nil};
        {<<"_">>, _} ->
            {error, nil};
        {<<"_", _/binary>>, $_} ->
            {error, nil};
        {<<First, _/binary>>, _} when not ?is_atom_char(First) ->
            {error, nil};
        {<<First, Rest/binary>>, none} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc, (inspect@uppercase(First))>>);
        {<<"_", Rest/binary>>, _} ->
            inspect@maybe_gleam_atom(Rest, $_, Acc);
        {<<First, Rest/binary>>, $_} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc, (inspect@uppercase(First))>>);
        {<<First, Rest/binary>>, _} ->
            inspect@maybe_gleam_atom(Rest, First, <<Acc, First>>);
        {<<>>, _} ->
            {ok, Acc};
        _ ->
            throw({gleam_error, echo, Atom, PrevChar, Acc})
    end.

inspect@uppercase(X) -> X - 32.
