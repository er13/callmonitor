##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2008  Andreas Bühmann <buehmann@users.berlios.de>
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
## This file based on telsearch.sh by niknak(@IPPF).
##
_reverse_search_ch_url() {
    local number="0${1#${LKZ_PREFIX}41}"
    URL="http://tel.search.ch/?tel=$(urlencode "$number")"
}
_reverse_search_ch_request() {
    local URL=
    _reverse_search_ch_url "$@"
    wget_callmonitor "$URL" -q -O -
}

_reverse_search_ch_extract() {
    sed -n -e '
	\#Keine Eintr..\?ge gefunden# {
	    '"$REVERSE_NA"'
	}
	\#^<div [^>]*class="tel_item"><div#,\#</div></div>$# {
	    \#<h5># b name
	    \#<span class="adrgroup# b address
	}
	b
	: name
	s#.*#<rev:name>&</rev:name>#
	h
	b
	: address
	H
	x
	'"$REVERSE_SANITIZE"'
	'"$REVERSE_OK"'
    '
}
