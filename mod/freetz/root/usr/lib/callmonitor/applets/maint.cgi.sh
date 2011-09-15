##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2008  Andreas B�hmann <buehmann@users.berlios.de>
## 
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
## 
## http://developer.berlios.de/projects/callmonitor/
##
require cgi
require if_jfritz_status
require if_jfritz_cgi

SELF=maint
TITLE='$(lang de:"Callmonitor-Wartung" en:"Callmonitor maintenance")'

cmd_button() {
    local cmd=$1 label=$2 method=post
    if empty "$cmd"; then
	method="get"
    fi
    echo "
<div class='btn'>
    <form class='btn' action='$SELF' method='$method'>
    	$(empty "$cmd" || echo "<input name='cmd' value='$cmd' type='hidden'>")
	<input value='$label' type='submit'>
    </form>
</div>
"
}

eval "$(modcgi cmd maint)"

if ! empty "$MAINT_CMD"; then
    cgi_begin "$TITLE ..."
    case $MAINT_CMD in
	phonebook_tidy)
	    echo "<p>$(lang de:"R�ume Telefonbuch auf" en:"Tidying up phone book"):</p>"
	    phonebook tidy 2>&1 | pre
	    ;;
	phonebook_init)
	    echo "<p>$(lang 
		de:"F�hre SIP-Update durch:"
		en:"Performing SIP update:"
	    )</p>"
	    phonebook init 2>&1 | pre
	    ;;
	phonebook_flush)
	    echo "<p>$(lang de:"Leere den R�ckw�rtssuche-Cache" en:"Flushing the reverse-lookup cache"):</p>"
	    phonebook flush 2>&1 | pre
	    ;;
	*)
	    echo "<p>$(lang de:"Unbekannter Befehl" en:"Unknown command")</p>"
	    ;;
    esac
    cmd_button '' '$(lang de:"Zur�ck" en:"Back")'
    cgi_end
    exit
fi

cgi_begin "$TITLE" extras

if have phonebook; then
sec_begin 'Telefonbuch (Callers)'

let LINES="$({ 
    grep '[[:print:]]' "$CALLMONITOR_PERSISTENT" | wc -l; } 2>/dev/null)+0"
let BYTES="$(wc -c < "$CALLMONITOR_PERSISTENT" 2>/dev/null)+0"
SIZE="$BYTES $(lang de:"Bytes" en:"bytes")"

echo "
<p>$(lang
    de:"$LINES Eintr�ge (Gr��e: $SIZE)
	<a href='$(href file callmonitor callers)'>bearbeiten</a>"
    en:"<a href='$(href file callmonitor callers)'>Edit</a>
	$LINES entries (size: $SIZE)"
)</p>
<p>$(lang
    de:"Beim Aufr�umen werden die Eintr�ge im Telefonbuch sortiert und
	Leerzeilen entfernt."
    en:"Tidying up the phone book will remove empty lines and sort entries."
)</p>
<p>$(lang
    de:"SIP-Update erstellt Standardeintr�ge f�r neu angelegte
	Internetrufnummern."
    en:"A SIP update creates default entries for newly installed Internet
	numbers."
)</p>
<p>$(lang
    de:"Der R�ckw�rtssuche-Cache kann hier geleert werden, um veraltete oder falsche Eintr�ge zu entfernen und so eine neue R�ckw�rtssuche zu erzwingen."
    en:"The reverse-lookup cache may be flushed in order to remove out-of-date or wrong entries and thus to enforce fresh reverse lookups."
)</p>
"
cmd_button phonebook_tidy '$(lang de:"Aufr�umen" en:"Tidy up")'
cmd_button phonebook_init '$(lang de:"SIP-Update durchf�hren" en:"Perform SIP update")'
cmd_button phonebook_flush '$(lang de:"Cache leeren" en:"Flush cache")'
sec_end
fi

sec_begin "$(lang de:"Schnittstellen" en:"Interfaces")"
echo "<ul>"
if _j_is_up; then
    _j_cgi_is_up
else
    _j_cgi_is_down
fi
echo "</ul>"
sec_end

cgi_end
