#!/bin/sh
BASE=/var/mobile/.ellamma
KEY=$(cat "$BASE/api_key")
MODEL="gpt-5.6-luna"
SESSION="ellamma-main"
STATE="$BASE/sessions/$SESSION"
PREV=""
[ -f "$STATE" ] && PREV=$(cat "$STATE")
printf "\nEllamma v0.2\n"
printf "iPhone 4S | iOS 6.1.3 | %s\n" "$MODEL"
printf "Type /help or /quit\n\n"
while true; do
printf "you> "
IFS= read -r INPUT || break
case "$INPUT" in
/quit|/exit) printf "Bye.\n"; break;;
/help) printf "/help  /new  /model  /quit\n"; continue;;
/new) SESSION="ellamma-$(date +%s)"; STATE="$BASE/sessions/$SESSION"; PREV=""; rm -f "$STATE"; printf "new session
"; continue;;
/model) printf "%s\n" "$MODEL"; continue;;
esac
printf "ellamma> "
if [ -n "$PREV" ]; then BODY=$(printf '{"model":"%s","input":"%s","previous_response_id":"%s"}' "$MODEL" "$INPUT" "$PREV"); else BODY=$(printf '{"model":"%s","input":"%s"}' "$MODEL" "$INPUT"); fi; RESP=$(curl -sS https://opencode.ai/zen/go/v1/responses -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "User-Agent: Ellamma/0.2 (iPhone4,1; iOS 6.1.3)" -H "x-opencode-session: $SESSION" --data "$BODY"); printf "%s" "$RESP" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p'; RESP_ID=$(printf "%s" "$RESP" | sed -n 's/^{"id":"\([^"]*\)".*/\1/p'); [ -n "$RESP_ID" ] && printf "%s" "$RESP_ID" > "$STATE" && PREV="$RESP_ID"
printf "\n\n"
done
