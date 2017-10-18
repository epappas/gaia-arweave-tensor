-module(ar_serialize).
-export([block_to_json/1, json_to_block/1, tx_to_json/1, json_to_tx/1]).
-include("ar.hrl").
-include_lib("eunit/include/eunit.hrl").

%%% Module containing serialisation/deserialisation utility functions
%%% for use in HTTP server.

%% @doc Take a JSON struct and produce JSON string.
jsonify(JSONStruct) ->
  lists:flatten(json2:encode(JSONStruct)).

%% @doc Decode JSON string into JSON struct.
dejsonify(JSON) ->
  json2:decode_string(JSON).

%% @doc Translate a block into JSON struct.
block_to_json(
	#block {
		nonce = Nonce,
		timestamp = TimeStamp,
		last_retarget = LastRetarget,
		diff = Diff,
		height = Height,
		hash = Hash,
		indep_hash = IndepHash,
		txs = TXs,
		hash_list = HashList,
		wallet_list = WalletList
	}) ->
	EncodedB =
		{struct,
			[
				{nonce, base64:encode_to_string(Nonce)},
				{timestamp, TimeStamp},
				{last_retarget, LastRetarget},
				{diff, Diff},
				{height, Height},
				{hash, base64:encode_to_string(Hash)},
				{indep_hash, base64:encode_to_string(IndepHash)},
				{txs, {array, lists:map(fun tx_to_json/1, TXs) }},
				{hash_list,
					{array, lists:map(fun base64:encode_to_string/1, HashList)}
				},
				{wallet_list,
					{array,
						lists:map(
							fun({Wallet, Qty}) ->
								{struct,
									[
										{wallet, base64:encode_to_string(Wallet)},
										{quantity, Qty}
									]
								}
							end,
							WalletList
						)
					}
				}
			]
		},
	jsonify(EncodedB).

%% @doc Translate fields parsed json from HTTP request into a block.
json_to_block(JSON) ->
	case dejsonify(JSON) of
		{ok, {struct, BlockStruct}}  ->
			{array, TXs} = find_value("txs", BlockStruct),
			{array, WalletList} = find_value("wallet_list", BlockStruct),
			{array, HashList} = find_value("hash_list", BlockStruct),
			#block {
				nonce = base64:decode(find_value("nonce", BlockStruct)),
				timestamp = find_value("timestamp", BlockStruct),
				last_retarget = find_value("last_retarget", BlockStruct),
				diff = find_value("diff", BlockStruct),
				height = find_value("height", BlockStruct),
				hash = base64:decode(find_value("hash", BlockStruct)),
				indep_hash = base64:decode(find_value("indep_hash", BlockStruct)),
				txs = lists:map(fun json_to_tx/1, TXs),
				hash_list = [ base64:decode(Hash) || Hash <- HashList ],
				wallet_list =
					[
						{base64:decode(Wallet), Qty}
					||
						{struct, [{"wallet", Wallet}, {"quantity", Qty}]}
							<- WalletList
					]
			};
		{_, {error, Reason}, _} ->
			ar:report([{json_error, Reason}])
	end.

%% @doc Translate a transaction into JSON.
tx_to_json(
	#tx {
		id = ID,
		owner = Owner,
		tags = Tags,
		target = Target,
		quantity = Quantity,
		type = Type,
		data = Data,
		signature = Sig
	}) ->
	EncodedTX =
		{struct,
			[
				{id, base64:encode_to_string(ID)},
				{owner, base64:encode_to_string(Owner)},
				{tags, {array, Tags}},
				{target, base64:encode_to_string(Target)},
				{quantity, Quantity},
				{type, atom_to_list(Type)},
				{data, base64:encode_to_string(Data)},
				{signature, base64:encode_to_string(Sig)}
			]
		},
	jsonify(EncodedTX).

%% @doc Translate parsed JSON from fields to a transaction.
json_to_tx(JSON) ->
	case dejsonify(JSON) of
		{ok, {struct, TXStruct}} ->
			{array, Tags} = find_value("tags", TXStruct),
			#tx {
				id = base64:decode(find_value("id", TXStruct)),
				owner = base64:decode(find_value("owner", TXStruct)),
				tags = Tags,
				target = base64:decode(find_value("target", TXStruct)),
				quantity = find_value("quantity", TXStruct),
				type = list_to_existing_atom(find_value("type", TXStruct)),
				data = base64:decode(find_value("data", TXStruct)),
				signature = base64:decode(find_value("signature", TXStruct))
			};
		{_, {error, Reason}, _} ->
			ar:report([{json_error, Reason}])
	end.

%% @doc Find the value associated with a key in a JSON structure list.
find_value(Key, List) ->
	case lists:keyfind(Key, 1, List) of
		{Key, Val} -> Val;
		false -> undefined
	end.

%% @doc Convert a new block into JSON and back, ensure the result is the same.
block_roundtrip_test() ->
	[B] = ar_weave:init(),
	JsonB = block_to_json(B),
	B1 = json_to_block(JsonB),
	B = B1.

%% @doc Convert a new TX into JSON and back, ensure the result is the same.
tx_roundtrip_test() ->
	TX = ar_tx:new(<<"TEST">>),
	JsonTX = tx_to_json(TX),
	TX1 = json_to_tx(JsonTX),
	TX = TX1.
