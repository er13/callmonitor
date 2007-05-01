##
## Callmonitor for Fritz!Box (callmonitor)
## 
## Copyright (C) 2005--2007  Andreas Bühmann <buehmann@users.berlios.de>
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

require webui
require url

dial() {
    local number=$1 port=$2
    _dial_port "$port" "telcfg:command/Dial=$(urlencode "$number")"
}

hangup() {
    local port=$1
    _dial_port "$port" "telcfg:command/Hangup"
}

_dial_port() {
    local port=$1 data=$2
    if ! empty "$port"; then
	data="telcfg:settings/DialPort=$(urlencode "$port")&$data"
    fi
    { webui_login; webui_post_form "$data"; } > /dev/null 2>&1
}
