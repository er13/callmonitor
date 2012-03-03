require if_jfritz_status
require hash

readonly var_jfritz="event id timestamp ext source dest remote duration provider state output uuid"

## analyze call information
__read() {
    local $var_jfritz
    export INSTANCE
    while _j_parse; do

	## complete information
	case $event in
	    CONNECT)	_j_load source dest provider ;;
	    DISCONNECT)	_j_load source dest provider ext ;;
	esac

	_j_load state uuid
	_j_transition
	
	case $state in
	    disconnected)
		_j_remove state source dest provider ext uuid
		;;
	    *)
		case $event in
		    RING) _j_store source dest provider ;;
		    CALL|CONNECT)   _j_store source dest provider ext ;;
		esac
		_j_store state uuid
		;;
	esac
    done
}

## separate state maschine for each connection id
_j_transition() {
    case $state in
	""|disconnected)
	    case $event in
		CALL)	    state=calling	output=out:request ;;
		RING)	    state=ringing	output=in:request ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	calling)
	    case $event in
		CONNECT)    state=connected:out	output=out:connect
			    dest=$remote ;;
		DISCONNECT) state=disconnected	output=out:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	ringing)
	    case $event in
		CALL)	    state=accepted:in	output=in:accept ;;
		CONNECT)    state=connected:in	output=in:connect
			    source=$remote ;;
		DISCONNECT) state=disconnected	output=in:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	accepted:in)
	    case $event in
		CONNECT)    state=connected:in	output=in:connect
			    source=$remote ;;
		DISCONNECT) state=disconnected	output=in:cancel ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	connected:in)
	    case $event in
		DISCONNECT) state=disconnected	output=in:disconnect ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
	connected:out)
	    case $event in
		DISCONNECT) state=disconnected	output=out:disconnect ;;
		*)	    state=disconnected  output=error ;;
	    esac
	;;
    esac
    let INSTANCE++
    if [ -z "$uuid" ]; then
	read -r uuid < /proc/sys/kernel/random/uuid
    fi
    case $output in
	""|in:accept)
	    ## not used yet
	;;
	*)
	    { _j_output "$output" & } & wait $!
	;;
    esac
}

_j_parse() {
    local _1 _2 _3 _4 _5 empty DEBUG
    IFS=";" read -r timestamp event _1 _2 _3 _4 _5 empty || return 1
    id=$_1
    DEBUG="timestamp=$timestamp event=$event id=$id"
    unset -v ext source dest remote duration provider
    case $event in
	CALL)
	    ext=$_2 source=$_3 dest=$_4 provider=$_5
	    DEBUG="$DEBUG ext=$ext source=$source dest=$dest provider=$provider"
	;;
	RING)
	    source=$_2 dest=$_3 provider=$_4
	    DEBUG="$DEBUG source=$source dest=$dest provider=$provider"
	;;
	CONNECT)
	    ext=$_2 remote=$_3
	    DEBUG="$DEBUG ext=$ext remote=$remote"
	;;
	DISCONNECT)
	    duration=$_2
	    DEBUG="$DEBUG duration=$duration"
	;;
	*)
	    return 1
	;;
    esac
    __debug '<<<' $DEBUG
    return 0
}

__read_from_iface() {
    local pidfile='/var/run/callmonitor/pid/sleep'
    _j_SLEEP=$(((_j_SLEEP < 1) ? 1 : _j_SLEEP))
    if ! _j_is_up; then
	__info "Auto-dialing #96*5* to enable telefon's interface ..."
	_j_enable
        __info "Trying again in $_j_SLEEP seconds ..."

	sleep "$_j_SLEEP"
	let "_j_SLEEP *= 3"
	let "_j_SLEEP = (_j_SLEEP > 3600) ? 3600 : _j_SLEEP"
    else
	_j_SLEEP=
	## hack to provide "never"-ending but empty stdin: FIXME
	{
	    sleep 20000d &
	    echo $! > "$pidfile"
	    wait
	    rm -f "$pidfile"
	} | {
	    busybox nc "${CALLMONITOR_MON_HOST:-127.0.0.1}" "${CALLMONITOR_MON_PORT:-1012}"
	    read pid < "$pidfile" && kill "$pid" > /dev/null 2>&1
	} | __read
    fi
}

__init_iface() {
    :
}

_j_output() {
    local output=$1
    local ID=$id SOURCE=$source DEST=$dest EXT=$ext DURATION=$duration
    local TIMESTAMP=$timestamp EVENT= SOURCE_OPTIONS= DEST_OPTIONS=
    local PROVIDER=$provider UUID=$uuid

    case $output in
	in:*)
	    EVENT=$output
	    DEST_OPTIONS="--local"
	;;
	out:*)
	    EVENT=$output
	    SOURCE_OPTIONS="--local"

	    ## strip end-of-number marker
	    DEST=${DEST%#}
	;;
    esac
    __debug '>>>' "$* ID=$ID TIMESTAMP=$TIMESTAMP SOURCE=$SOURCE DEST=$DEST" \
	"EXT=$EXT DURATION=$DURATION PROVIDER=$PROVIDER"

    if ! empty "$EVENT"; then
	unset -v $var_jfritz
	incoming_call
    fi
}

## store attributes per connection id
new_hash _j_
_j_store() {
    local var
    for var; do eval "_j__put ${var}_${id} \"\$$var\""; done
}
_j_load() {
    local var
    for var; do _j__get ${var}_${id} "$var"; done
}
_j_remove() {
    local var
    for var; do unset -v $var; _j__remove ${var}_${id}; done
}
