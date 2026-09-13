#!/bin/sh
banner()
{
	printf "\nEllamma v%s\n" "$VERSION"
	printf "%s %s | %s\n" "$(uname -s)" "$(uname -m)" "$MODEL"
	printf "Type /help or /quit\n\n"
}

handle_input()
{
	case "$INPUT" in
		/quit|/exit) printf "Bye.\n"; return 1;;
		/help) printf "/help  /new  /model  /quit\n"; return 0;;
		/new) new_session; printf "new session\n"; return 0;;
		/model) printf "%s\n" "$MODEL"; return 0;;
	esac
	printf "ellamma> "
	ask
	printf "\n\n"
	[ -n "$RESP_ID" ] && save_prev
	return 0
}

repl()
{
	banner
	init_state || { printf "Ellamma: cannot create %s\n" "$STATE_DIR" >&2; return 1; }
	load_prev
	while true; do
		printf "you> "
		IFS= read -r INPUT || break
		handle_input || break
	done
}