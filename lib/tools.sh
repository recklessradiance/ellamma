#!/bin/sh
TAB=$(printf '\t')

curlf()
{
	CACERT=
	[ -f "$BASE/cacert.pem" ] && CACERT="--cacert $BASE/cacert.pem"
	curl -sSL --max-time 25 $CACERT "$@" || curl -skSL --max-time 25 "$@"
}

html_to_text()
{
	awk '
	function tolow(s,   o, i, c) {
		o = ""
		for (i = 1; i <= length(s); i++) {
			c = substr(s, i, 1)
			if (c >= "A" && c <= "Z") c = sprintf("%c", index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c) + 96)
			o = o c
		}
		return o
	}
	BEGIN { hide = 0 }
	{
		out = ""; tag = ""; inTag = 0
		for (i = 1; i <= length($0); i++) {
			c = substr($0, i, 1)
			if (inTag) {
				tag = tag c
				if (c == ">") {
					inTag = 0
					LOW = tolow(tag); tag = ""
					if (LOW ~ /^<\/ *script[ >]/ || LOW ~ /^<\/ *style[ >]/) hide = 0
					else if (LOW ~ /^< *(script|style)[ >\t]/) hide = 1
				}
				continue
			}
			if (c == "<") { inTag = 1; tag = "<"; continue }
			if (!hide) out = out c
		}
		gsub(/[ \t]+/, " ", out)
		gsub(/&nbsp;/, " ", out)
		gsub(/&amp;/, "&", out)
		gsub(/&lt;/, "<", out)
		gsub(/&gt;/, ">", out)
		gsub(/&quot;/, "\"", out)
		gsub(/&#39;/, sprintf("%c", 39), out)
		gsub(/^ +| +$/, "", out)
		if (out != "") print out
	}
	'
}

truncate()
{
	awk -v max="${1:-4000}" '
		{
			if (total + length($0) + 1 > max) {
				if (total < max) print substr($0, 1, max - total - 1)
				exit
			}
			total = total + length($0) + 1
			print
		}
	'
}

json_escape()
{
	awk '
		{ gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); gsub(/\r/, "\\r"); printf "%s\\n", $0 }
	'
}

tool_fetch_url()
{
	URL="$1"
	case "$URL" in
		http://*|https://*) ;;
		*) printf 'invalid or unsupported URL (must be http:// or https://)\n'; return;;
	esac
	curlf "$URL" | html_to_text | truncate 6000
}

tool_web_search()
{
	Q="$1"
	[ -n "$Q" ] || { printf 'empty query\n'; return; }
	HTML=$(curlf -A 'Mozilla/5.0 (X11; Linux) HTML' 'https://html.duckduckgo.com/html/' --data-urlencode "q=$Q")
	OUT=$(printf '%s' "$HTML" | ddg_parse)
	[ -n "$OUT" ] || OUT=$(wiki_search "$Q")
	[ -n "$OUT" ] || OUT='no search results'
	printf '%s' "$OUT" | truncate 4000
}

ddg_parse()
{
	awk '
		function clean(t,   o, i, c) {
			o = ""
			for (i = 1; i <= length(t); i++) {
				c = substr(t, i, 1)
				if (c == "<") { while (i <= length(t) && substr(t, i, 1) != ">") i++; continue }
				o = o c
			}
			gsub(/&nbsp;/, " ", o); gsub(/&amp;/, "&", o); gsub(/&lt;/, "<", o)
			gsub(/&gt;/, ">", o); gsub(/&quot;/, "\"", o); gsub(/&#39;/, sprintf("%c", 39), o)
			gsub(/^ +| +$/, "", o); gsub(/[ \t]+/, " ", o)
			return o
		}
		{
			line = $0
			n = split(line, parts, "href=")
			for (k = 2; k <= n; k++) {
				val = parts[k]
				num = index(val, ">")
				if (num <= 0) continue
				before = substr(val, 1, num - 1)
				if (index(before, ">") != 0) continue
				q = substr(val, 1, 1)
				cl = index(substr(val, 2), q)
				if (cl <= 0) continue
				ce = cl + 1
				url = substr(val, 2, ce - 2)
				if (url ~ /^\//) url = "https:" url
				if (url !~ /^https?:\/\//) continue
				gt = index(val, ">")
				ae = index(val, "</a>")
				if (gt <= ce || ae <= gt) continue
				title = clean(substr(val, gt + 1, ae - gt - 1))
				if (title != "") print title " | " url
			}
		}
		/snippet/ {
			line = $0
			p = index(line, "snippet")
			if (p <= 0) next
			tail = substr(line, p)
			gt = index(tail, ">")
			if (gt <= 0) next
			after = substr(tail, gt + 1)
			ae = index(after, "</a>")
			if (ae <= 0) ae = length(after) + 1
			s = clean(substr(after, 1, ae - 1))
			if (s != "") print "  " s
		}
	'
}

wiki_search()
{
	WJSON=$(curlf 'https://en.wikipedia.org/w/api.php' -G \
		--data-urlencode action=query \
		--data-urlencode list=search \
		--data-urlencode srsearch="$1" \
		--data-urlencode format=json \
		--data-urlencode srlimit=6)
	[ -n "$WJSON" ] || return 0
	printf '%s' "$WJSON" | awk '
		function clean(t,   o, i, c) {
			o = ""
			for (i = 1; i <= length(t); i++) {
				c = substr(t, i, 1)
				if (c == "<") { while (i <= length(t) && substr(t, i, 1) != ">") i++; continue }
				o = o c
			}
			gsub(/[ \t]+/, " ", o); gsub(/^ +| +$/, "", o)
			return o
		}
		{
			line = $0
			n = split(line, chunks, "\"title\":\"")
			for (k = 2; k <= n; k++) {
				ch = chunks[k]
				te = index(ch, "\"")
				title = te > 0 ? substr(ch, 1, te - 1) : ch
				sp = index(ch, "\"snippet\":\"")
				snippet = "N/A"
				if (sp > 0) {
					rest = substr(ch, sp + length("\"snippet\":\"") - 1)
					se = index(rest, "\"")
					snippet = se > 0 ? substr(rest, 1, se - 1) : rest
				}
				printf "%s | https://en.wikipedia.org/wiki/%s\n  %s\n", clean(title), title, clean(snippet)
			}
		}
	'
}

tool_dispatch()
{
	case "$1" in
		web_search) shift; tool_web_search "$1";;
		fetch_url) shift; tool_fetch_url "$1";;
		*) printf 'unknown tool %s\n' "$1";;
	esac
}