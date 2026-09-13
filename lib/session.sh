#!/bin/sh
init_state()
{
	mkdir -p "$STATE_DIR" 2>/dev/null || return 1
}

load_prev()
{
	PREV=""
	[ -f "$STATE" ] && PREV=$(cat "$STATE")
}

save_prev()
{
	[ -n "$RESP_ID" ] || return 0
	printf '%s' "$RESP_ID" > "$STATE"
}

new_session()
{
	SESSION_NAME="ellamma-$(date +%s)"
	STATE="$STATE_DIR/$SESSION_NAME"
	rm -f "$STATE"
	PREV=""
	RESP_ID=""
}