#!/bin/sh
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"
. "$SCRIPT_DIR/lib/session.sh"
. "$SCRIPT_DIR/lib/markdown.sh"
. "$SCRIPT_DIR/lib/api.sh"
. "$SCRIPT_DIR/lib/ui.sh"

repl