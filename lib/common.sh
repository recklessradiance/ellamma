#!/bin/sh
if [ -n "${ELLAMMA_HOME:-}" ]; then
	BASE="$ELLAMMA_HOME"
elif mkdir -p /var/mobile/.ellamma 2>/dev/null || [ -w /var/mobile/.ellamma ]; then
	BASE=/var/mobile/.ellamma
else
	BASE="$HOME/.ellamma"
fi
MODEL="${ELLAMMA_MODEL:-gpt-5.6-luna}"
SESSION_NAME="${ELLAMMA_SESSION:-ellamma-main}"
STATE_DIR="$BASE/sessions"
STATE="$STATE_DIR/$SESSION_NAME"
KEY=""
PREV=""
RESP=""
RESP_ID=""
VERSION="0.3"
API_ENDPOINT="https://opencode.ai/zen/go/v1/responses"
UA="Ellamma/$VERSION ($(uname -s) $(uname -m))"