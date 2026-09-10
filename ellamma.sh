#!/bin/sh
BASE=/var/mobile/.ellamma
KEY=$(cat "$BASE/api_key")
MODEL="gpt-5.6-luna"
SESSION="ellamma-$(date +%s)"
printf "\nEllamma v0.1\n"
printf "iPhone 4S | iOS 6.1.3 | %s\n" "$MODEL"
printf "Type /help or /quit\n\n"
while true; do
printf "you> "
IFS= read -r INPUT || break
case "$INPUT" in
/quit|/exit) printf "Bye.\n"; break;;
/help) printf "/help  /new  /model  /quit\n"; continue;;
/new) SESSION="ellamma-$(date +%s)"; printf "new session\n"; continue;;
/model) printf "%s\n" "$MODEL"; continue;;
esac
printf "ellamma> "
curl -sS https://opencode.ai/zen/go/v1/responses -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -H "User-Agent: Ellamma/0.1 (iPhone4,1; iOS 6.1.3)" -H "x-opencode-session: $SESSION" -d "{\"model\":\"$MODEL\",\"input\":\"$INPUT\"}" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p'
printf "\n\n"
done
