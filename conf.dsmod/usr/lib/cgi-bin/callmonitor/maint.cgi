#!/bin/sh
. "${CALLMONITOR_CFG:=/mod/etc/default.callmonitor/system.cfg}"
require cgi

SELF=maint
TITLE='Callmonitor-Wartung'

cmd_button() {
	local cmd="$1" label="$2" method="post"
	if [ -z "$cmd" ]; then
		method="get"
	fi
	cat << EOF
<div class="btn"><form class="btn" action="$SELF" method="$method"><input name="cmd" value="$1" type="hidden"><input value="$2" type="submit"></form></div>
EOF
}

eval "$(modcgi cmd maint)"

if [ -n "$MAINT_CMD" ]; then
	cgi_begin "$TITLE ..."
	case "$MAINT_CMD" in
		phonebook_tidy)
			echo "<p>R�ume Callers auf:</p>"
			phonebook tidy 2>&1 | pre
			;;
		phonebook_init)
			echo "<p>SIP-Update wird durchgef�hrt.</p>"
			phonebook init 2>&1 | pre
		*)
			echo "<p>Unbekannter Befehl</p>"
			;;
	esac
	cmd_button '' 'Zur�ck'
	cgi_end
	exit
fi

cgi_begin "$TITLE" extras
sec_begin 'Callers'

let LINES="$({ 
	grep '[[:print:]]' "$CALLMONITOR_PERSISTENT" | wc -l; } 2>/dev/null)+0"
let BYTES="$(wc -c < "$CALLMONITOR_PERSISTENT" 2>/dev/null)+0"
SIZE="$BYTES Bytes"

cat << EOF
<p>$LINES Eintr�ge (Gr��e: $SIZE)
	<a href="/cgi-bin/file.cgi?id=callers">bearbeiten</a></p>
<p>Beim Aufr�umen werden die Eintr�ge im Telefonbuch sortiert und Leerzeilen
entfernt.</p>
<p>SIP-Update erstellt Standardeintr�ge f�r neu angelegte
Internetrufnummern.</p>
EOF
cmd_button phonebook_tidy 'Aufr�umen'
cmd_button phonebook_init 'SIP-Update'
sec_end
cgi_end
