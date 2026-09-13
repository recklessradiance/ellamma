#!/bin/sh
# install.sh - install ellamma into the runtime base directory
#
#   ./install.sh            install (default)
#   ./install.sh uninstall  remove the installed runtime
#
# Installs into $ELLAMMA_HOME (default: ~/.ellamma) as <base>/bin, places a
# launcher on PATH (default: ~/.local/bin/ellamma), and bootstraps the API key
# if none is present.

set -e

usage()
{
	echo "usage: $0 [install|uninstall]" >&2
	exit 2
}

resolve_base()
{
	if [ -n "${ELLAMMA_HOME:-}" ]; then
		BASE="$ELLAMMA_HOME"
	elif mkdir -p /var/mobile/.ellamma 2>/dev/null || [ -w /var/mobile/.ellamma ]; then
		BASE=/var/mobile/.ellamma
	else
		BASE="$HOME/.ellamma"
	fi
}

do_install()
{
	resolve_base
	BINDIR="${ELLAMMA_BIN:-$HOME/.local/bin}"
	SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

	if [ ! -f "$SCRIPT_DIR/ellamma.sh" ] || [ ! -d "$SCRIPT_DIR/lib" ]; then
		echo "ellamma: run install.sh from the project directory (ellamma.sh/lib missing)" >&2
		exit 1
	fi

	mkdir -p "$BASE/bin/lib"
	cp "$SCRIPT_DIR/ellamma.sh" "$BASE/bin/ellamma.sh"
	cp "$SCRIPT_DIR/lib/common.sh" \
	   "$SCRIPT_DIR/lib/session.sh" \
	   "$SCRIPT_DIR/lib/markdown.sh" \
	   "$SCRIPT_DIR/lib/tools.sh" \
	   "$SCRIPT_DIR/lib/api.sh" \
	   "$SCRIPT_DIR/lib/ui.sh" \
	   "$BASE/bin/lib/"
	chmod 755 "$BASE/bin/ellamma.sh" "$BASE/bin/lib"/*.sh

	mkdir -p "$BINDIR"
	cat > "$BINDIR/ellamma" <<EOF
#!/bin/sh
if [ -n "\${ELLAMMA_HOME:-}" ]; then
	BASE="\$ELLAMMA_HOME"
elif [ -w /var/mobile/.ellamma ]; then
	BASE=/var/mobile/.ellamma
else
	BASE="\$HOME/.ellamma"
fi
export ELLAMMA_HOME="\$BASE"
exec "\$BASE/bin/ellamma.sh" "\$@"
EOF
	chmod 755 "$BINDIR/ellamma"

	if [ -s "$BASE/api_key" ]; then
		KEY_PRESENT=1
	else
		KEY_PRESENT=0
	fi

	chmod 700 "$BASE" 2>/dev/null || true
	mkdir -p "$BASE/sessions" 2>/dev/null || true
	chmod 700 "$BASE/sessions" 2>/dev/null || true

	if [ "$KEY_PRESENT" -eq 0 ]; then
		printf '%s' 'OpenCode Go API key (input hidden): '
		stty -echo 2>/dev/null || true
		IFS= read -r KEY_VALUE || KEY_VALUE=""
		stty echo 2>/dev/null || true
		printf '\n'
		if [ -z "$KEY_VALUE" ]; then
			echo "ellamma: no key provided; run 'install.sh' again or write <base>/api_key manually" >&2
			exit 1
		fi
		printf '%s\n' "$KEY_VALUE" > "$BASE/api_key"
		chmod 600 "$BASE/api_key"
	fi

	echo "installed:"
	echo "  runtime   $BASE/bin"
	echo "  launcher  $BINDIR/ellamma"
	echo "  api key   $BASE/api_key ($([ "$KEY_PRESENT" -eq 1 ] && echo 'kept' || echo 'written'))"
	echo "start with: $BINDIR/ellamma"
}

do_uninstall()
{
	resolve_base
	BINDIR="${ELLAMMA_BIN:-$HOME/.local/bin}"
	rm -f "$BINDIR/ellamma"
	rm -rf "$BASE/bin"
	echo "removed $BINDIR/ellamma and $BASE/bin (kept $BASE/api_key and $BASE/sessions)"
}

case "${1:-install}" in
	install) do_install;;
	uninstall) do_uninstall;;
	*) usage;;
esac