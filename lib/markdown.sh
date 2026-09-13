#!/bin/sh
LF='
'
if [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != dumb ]; then
	MD_COLOR=0
else
	MD_COLOR=1
fi
MD_FENCE=0
MD_BUF=""

MD_AWK_PROG='
BEGIN {
	F  = (st == 1) ? 1 : 0
	B  = "\033[1m"
	R  = "\033[0m"
	H  = "\033[1;34m"
	C  = "\033[36m"
	Fb = "\033[32m"
	D  = "\033[2m"
	Bu = "\033[33m"
	if (nocolor + 0 == 1) { B = R = H = C = Fb = D = Bu = "" }
	SENT = "\002"
	hav = 0
	prev = ""
}
function emit(r) {
	if (r != SENT) print r
}
function inline(l,   s, t, lt, j) {
	while (match(l, /\[[^]]*\]\([^)]*\)/)) {
		s = substr(l, RSTART, RLENGTH)
		j = index(s, "]")
		lt = substr(s, 2, j - 2)
		l = substr(l, 1, RSTART - 1) H lt R substr(l, RSTART + RLENGTH)
	}
	while (match(l, /`[^`]*`/)) {
		s = substr(l, RSTART, RLENGTH); t = substr(s, 2, length(s) - 2)
		l = substr(l, 1, RSTART - 1) C t R substr(l, RSTART + RLENGTH)
	}
	while (match(l, /\*\*[^*]*\*\*/)) {
		s = substr(l, RSTART, RLENGTH); t = substr(s, 3, length(s) - 4)
		l = substr(l, 1, RSTART - 1) B t R substr(l, RSTART + RLENGTH)
	}
	while (match(l, /~~[^~]*~~/)) {
		s = substr(l, RSTART, RLENGTH); t = substr(s, 3, length(s) - 4)
		l = substr(l, 1, RSTART - 1) D t R substr(l, RSTART + RLENGTH)
	}
	while (match(l, /\*[^*\n]+\*/)) {
		s = substr(l, RSTART, RLENGTH); t = substr(s, 2, length(s) - 2)
		l = substr(l, 1, RSTART - 1) D t R substr(l, RSTART + RLENGTH)
	}
	while (match(l, /_[^_\n]+_/)) {
		s = substr(l, RSTART, RLENGTH); t = substr(s, 2, length(s) - 2)
		l = substr(l, 1, RSTART - 1) D t R substr(l, RSTART + RLENGTH)
	}
	return l
}
function transform(l,   pre, r) {
	if (F == 1) {
		if (l ~ /^```/) {
			print D "-----------------" R
			F = 0
			return SENT
		}
		if (l ~ /```[ \t]*$/) {
			sub(/```[ \t]*$/, "", l)
			if (l != "") print Fb "│ " l R
			print D "-----------------" R
			F = 0
			return SENT
		}
		return Fb "│ " l R
	}
	if (l ~ /^```/) {
		print D "----- code -----" R
		F = 1
		return SENT
	}
	if (l ~ /```[ \t]*$/) {
		sub(/```[ \t]*$/, "", l)
		if (l != "") print l
		print D "----- code -----" R
		F = 1
		return SENT
	}
	if (l ~ /^#+[ \t]/) {
		r = l
		match(r, /^#+[ \t]+/)
		r = substr(r, RLENGTH + 1)
		return H B r R
	}
	if (l ~ /^-{3,}$/ || l ~ /^\*{3,}$/ || l ~ /^_{3,}$/) {
		return D "---------------------" R
	}
	if (l ~ /^[ \t]*[-*+][ \t]+\[[ xX]\]/) {
		match(l, /^[ \t]*[-*+][ \t]+/)
		pre = substr(l, 1, RSTART - 1)
		r = substr(l, RLENGTH + 1)
		if (r ~ /^\[x\]/) sub(/^\[x\]/, "✓", r); else sub(/^\[ \]/, "☐", r)
		return pre Bu r R
	}
	if (l ~ /^[ \t]*[-*+][ \t]+/) {
		match(l, /^[ \t]*[-*+][ \t]+/)
		pre = substr(l, 1, RSTART - 1)
		r = substr(l, RLENGTH + 1)
		return pre Bu "●" R " " inline(r)
	}
	if (l ~ /^[ \t]*[0-9]+[.)][ \t]+/) {
		match(l, /^[ \t]*[0-9]+[.)][ \t]+/)
		pre = substr(l, 1, RSTART - 1)
		r = substr(l, RLENGTH + 1)
		return pre Bu "·" R " " inline(r)
	}
	if (l ~ /^>[ \t]?/) {
		r = l
		sub(/^>[ \t]?/, "", r)
		return D "│ " r R
	}
	return inline(l)
}
{
	n++
	line[n] = $0
}
END {
	lim = n
	last = ""
	if (endnl == 0 && n >= 1) { last = line[n]; lim = n - 1 }
	for (i = 1; i <= lim; i++) {
		r = transform(line[i])
		if (r != SENT) print r
	}
	print F > cfile
	if (endnl == 0) print last > cfile
}
'

md_drain()
{
	case "$MD_BUF" in
		*"$LF"*) ;;
		*) return 0;;
	esac
	case "$MD_BUF" in
		*"$LF") MD_ENDNL=1;;
		*) MD_ENDNL=0;;
	esac
	MWF="$BASE/.md.$$"
	: > "$MWF"
	printf '%s' "$MD_BUF" | LC_ALL=C awk \
		-v st="$MD_FENCE" \
		-v endnl="$MD_ENDNL" \
		-v nocolor="$MD_COLOR" \
		-v cfile="$MWF" \
		"$MD_AWK_PROG"
	MD_F=$(sed -n '1p' "$MWF")
	MD_PART=$(sed -n '2p' "$MWF")
	rm -f "$MWF"
	[ -n "$MD_F" ] && MD_FENCE=$MD_F
	MD_BUF=$MD_PART
}

md_emit()
{
	MD_BUF=${MD_BUF}${1}
	md_drain
}

md_flush()
{
	if [ -n "$MD_BUF" ]; then
		case "$MD_BUF" in
			*"$LF") ;;
			*) MD_BUF=${MD_BUF}${LF};;
		esac
		md_drain
	fi
	MD_BUF=""
	MD_FENCE=0
}