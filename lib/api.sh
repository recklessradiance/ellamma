#!/bin/sh
TAB=$(printf '\t')
MAXTOOLS=8
TOOLROUND=0
TOOL_INPUT=""

TOOLS_JSON='[{"type":"function","name":"web_search","description":"Search the web for current information. Returns result titles, links and short snippets. Use when the user asks about recent events, live data, or anything the model may not know.","parameters":{"type":"object","properties":{"query":{"type":"string"}},"required":["query"],"additionalProperties":false}},{"type":"function","name":"fetch_url","description":"Fetch a single web page and return its visible text content. Use for pages whose full content is needed, such as articles, documentation or search results.","parameters":{"type":"object","properties":{"url":{"type":"string"}},"required":["url"],"additionalProperties":false}}]'

unescape()
{
	T=$(printf '%sa' "$1" | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g' -e 's/\\n/\n/g' -e "s/\\t/$TAB/g")
	T=${T%a}
	printf '%s' "$T"
}

extract_delta()
{
	awk '
		{
			s = $0
			p = index(s, "\"delta\":\"")
			if (p == 0) next
			out = ""
			i = p + 9
			while (i <= length(s)) {
				c = substr(s, i, 1)
				if (c == "\\") {
					if (i < length(s)) out = out c substr(s, i + 1, 1)
					i += 2
					continue
				}
				if (c == "\"") break
				out = out c
				i++
			}
			print out
		}
	'
}

build_body()
{
	if [ "$TOOLROUND" -ge 1 ] && [ -n "$TOOL_INPUT" ]; then
		BODY_IN="$TOOL_INPUT"
		BODY_FMT='"input":%s'
	else
		BODY_IN="$INPUT"
		BODY_FMT='"input":"%s"'
	fi
	PREV_BIT=""
	[ -n "$PREV" ] && PREV_BIT=",\"previous_response_id\":\"$PREV\""
	printf '{"model":"%s","instructions":"%s",%s%s,"stream":true,"tools":%s}' \
		"$MODEL" "$SYSCTX" "$(printf "$BODY_FMT" "$BODY_IN")" "$PREV_BIT" "$TOOLS_JSON"
}

run_tool_calls()
{
	ARGSF="$1"
	CALLSF="$2"
	[ -s "$CALLSF" ] || return 0
	ITEMS="["
	SEP=""
	while IFS= read -r ITEM_NAME_CALL; do
		ITEM=${ITEM_NAME_CALL%%$TAB*}
		REST=${ITEM_NAME_CALL#*$TAB}
		NAME=${REST%%$TAB*}
		CALL_ID=${REST#*$TAB}
		ARGS=$(cat "$ARGSF/$ITEM" 2>/dev/null)
		ARGU=$(unescape "$ARGS")
		ARG=$(printf '%s' "$ARGU" | sed -n 's/.*"query":"\([^"]*\)".*/\1/p')
		[ -n "$ARG" ] || ARG=$(printf '%s' "$ARGU" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
		case "$NAME" in
			web_search) printf "\n  [search: %s]\n\n" "$ARG" >&9;;
			fetch_url) printf "\n  [fetch: %s]\n\n" "$ARG" >&9;;
			*) printf "\n  [%s]\n\n" "$NAME" >&9;;
		esac
		RESULT=$(tool_dispatch "$NAME" "$ARG")
		RESULT=$(printf '%s' "$RESULT" | json_escape)
		ITEMS="$ITEMS$SEP{\"type\":\"function_call_output\",\"call_id\":\"$CALL_ID\",\"output\":\"$RESULT\"}"
		SEP=","
	done < "$CALLSF"
	ITEMS="$ITEMS]"
	printf '%s' "$ITEMS"
}

ask()
{
	[ -n "$KEY" ] || KEY=$(cat "$BASE/api_key" 2>/dev/null)
	[ -n "$KEY" ] || return 1
	RESP_ID=""
	exec 9>&1
	BODY=$(build_body)
	CACERT=
	[ -f "$BASE/cacert.pem" ] && CACERT="--cacert $BASE/cacert.pem"
	attempt=0
	GOT=""
	while [ "$attempt" -lt 3 ]; do
		STREAM="$BASE/.stream.$$"
		ARGSF="$BASE/.args.$$"
		CALLSF="$BASE/.calls.$$"
		rm -f "$STREAM"
		mkfifo "$STREAM" && { rm -rf "$ARGSF"; mkdir -p "$ARGSF"; : > "$CALLSF"; } || {
			printf "(stream error, retry %s/3)\n" "$((attempt + 2))" >&2
			attempt=$((attempt + 1))
			continue; }
		curl -sSN "$API_ENDPOINT" $CACERT \
			-H "Authorization: Bearer $KEY" \
			-H "Content-Type: application/json" \
			-H "User-Agent: $UA" \
			-H "x-opencode-session: $SESSION_NAME" \
			--data "$BODY" > "$STREAM" 2>/dev/null &
		CURL_PID=$!
		GOT=""
		exec 3< "$STREAM"
		while IFS= read -r LINE <&3; do
			case "$LINE" in
				data:*)
					GOT=1
					DATA=${LINE#data: }
				case "$DATA" in
					"[DONE]") break;;
					*'"type":"response.output_text.delta"'*)
						T=$(printf '%s' "$DATA" | sed -n 's/.*"delta":"\([^"]*\)".*/\1/p')
						[ -n "$T" ] || continue
						T=$(unescape "$T")
						md_emit "$T";;
					*'"type":"response.output_item.added"'*)
						case "$DATA" in
							*'"type":"function_call"'*)
								ITEM=$(printf '%s' "$DATA" | sed -n 's/.*"item":{"id":"\([^"]*\)".*/\1/p')
								NAME=$(printf '%s' "$DATA" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
								CALL=$(printf '%s' "$DATA" | sed -n 's/.*"call_id":"\([^"]*\)".*/\1/p')
								[ -n "$ITEM" ] && [ -n "$NAME" ] && [ -n "$CALL" ] \
									&& printf '%s%s%s%s%s\n' "$ITEM" "$TAB" "$NAME" "$TAB" "$CALL" >> "$CALLSF"
								;;
						esac;;
					*'"type":"response.function_call_arguments.delta"'*)
						ITEM=$(printf '%s' "$DATA" | sed -n 's/.*"item_id":"\([^"]*\)".*/\1/p')
						DELTA=$(printf '%s' "$DATA" | extract_delta)
						[ -n "$ITEM" ] && [ -n "$DELTA" ] && printf '%s' "$DELTA" >> "$ARGSF/$ITEM"
						;;
				esac
				I=$(printf '%s' "$DATA" | sed -n 's/.*"response":{"id":"\([^"]*\)".*/\1/p')
				[ -n "$I" ] && RESP_ID="$I";;
		esac
	done
	exec 3<&-
		wait "$CURL_PID" 2>/dev/null
		rm -f "$STREAM"
		[ -n "$GOT" ] && break
		attempt=$((attempt + 1))
		[ "$attempt" -lt 3 ] && printf "(no response from model, retry %s/3)\n" "$((attempt + 1))" >&2
	done
	[ -n "$GOT" ] || printf "(no response from model after retries)\n" >&2
	OUT=$(run_tool_calls "$ARGSF" "$CALLSF")
	rm -rf "$ARGSF" "$CALLSF"
	if [ -n "$OUT" ] && [ "$TOOLROUND" -lt "$MAXTOOLS" ]; then
		md_flush
		TOOLROUND=$((TOOLROUND + 1))
		TOOL_INPUT="$OUT"
		PREV="$RESP_ID"
		ask
		return
	fi
	TOOL_INPUT=""
	md_flush
	[ -n "$RESP_ID" ] && PREV="$RESP_ID"
}