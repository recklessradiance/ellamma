#!/bin/sh
ask()
{
	[ -n "$KEY" ] || KEY=$(cat "$BASE/api_key" 2>/dev/null)
	[ -n "$KEY" ] || return 1
	STREAM="$BASE/.stream.$$"
	rm -f "$STREAM"
	mkfifo "$STREAM" || return 1
	RESP_ID=""
	if [ -n "$PREV" ]; then
		BODY=$(printf '{"model":"%s","input":"%s","previous_response_id":"%s","stream":true}' "$MODEL" "$INPUT" "$PREV")
	else
		BODY=$(printf '{"model":"%s","input":"%s","stream":true}' "$MODEL" "$INPUT")
	fi
	curl -sSN "$API_ENDPOINT" \
		-H "Authorization: Bearer $KEY" \
		-H "Content-Type: application/json" \
		-H "User-Agent: $UA" \
		-H "x-opencode-session: $SESSION_NAME" \
		--data "$BODY" > "$STREAM" 2>/dev/null &
	CURL_PID=$!
	exec 3< "$STREAM"
	while IFS= read -r LINE <&3; do
		case "$LINE" in
			data:*)
				DATA=${LINE#data: }
				case "$DATA" in
					"[DONE]") break;;
					*'"type":"response.output_text.delta"'*)
						T=$(printf '%s' "$DATA" | sed -n 's/.*"delta":"\([^"]*\)".*/\1/p')
						[ -n "$T" ] || continue
						T=$(printf '%sa' "$T" | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g' -e 's/\\n/\n/g' -e "s/\\t/$TAB/g")
						T=${T%a}
						md_emit "$T";;
				esac
				I=$(printf '%s' "$DATA" | sed -n 's/.*"response":{"id":"\([^"]*\)".*/\1/p')
				[ -n "$I" ] && RESP_ID="$I";;
		esac
	done
	exec 3<&-
	wait "$CURL_PID" 2>/dev/null
	rm -f "$STREAM"
	md_flush
	[ -n "$RESP_ID" ] && PREV="$RESP_ID"
}