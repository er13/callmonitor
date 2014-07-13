DAEMON=callmonitor

require rc
require modreg
require file

FIFO=$CALLMONITOR_FIFO
FIFO_DIR=${FIFO%/*}
ensure_dir "$FIFO_DIR"
PIDFILE="/var/run/$DAEMON/pid/$DAEMON"

case $1 in
    ""|load|start|restart)
	if [ ! -r "$CALLMONITOR_USERCFG" ]; then
	    echo "Error[$DAEMON]: not configured" >&2
	    exit 1
	fi
	;;
esac

if have monitor; then
    start_daemon() {
	echo -n "Starting $DAEMON ... "
	case $CALLMONITOR_DEBUG in
	    yes) "$DAEMON" --debug > /dev/null 2>&1 ;; 
	    *) "$DAEMON" > /dev/null 2>&1 ;;
	esac
	check_status
    }
    stop_daemon() {
	echo -n "Stopping $DAEMON ... "
	if ! is_running; then
		echo 'not running.'
	else
		"$DAEMON" -s
		check_status
	fi
    }
else
    start_daemon() {
	echo "$DAEMON is not installed"
	return 1
    }
    stop_daemon() start_daemon
fi

try_start() {
    case $CALLMONITOR_ENABLED in yes) ;; *)
	echo "$DAEMON is disabled" >&2
	exit 1
    ;; esac

    start
}
start() {
    local exitval=0
    if is_running; then
	echo "$DAEMON already started."
	exit 0
    fi
    if have phonebook; then
	phonebook start 2>&1 > /dev/null
    fi
    start_daemon || exitval=$?
    return $exitval
}
stop() {
    local exitval=0
    stop_daemon || exitval=$?
    return $exitval
}
restart() {
    stop
    start
}

is_running() {
    local pid
    [ -e "$PIDFILE" ] && read pid < "$PIDFILE" && 
	kill -0 "$pid" 2> /dev/null
}

case $1 in
    ""|load)
	mod_register
	if have phonebook; then
	    phonebook init 2> /dev/null
	fi
	if have monitor; then
	    try_start
	fi
	;;
    unload)
	stop
	mod_unregister
	;;
    try-start)
	try_start
	;;
    start)
	start
	;;
    stop)
	stop
	;;
    restart)
	restart
	;;
    status)
	if is_running; then
	    echo "running"
	else
	    echo "stopped"
	fi
	;;
    reload)
	if ! is_running; then
	    echo "$DAEMON is not running" >&2
	    exit 1
	fi
	read pid < "$PIDFILE" &&
	    kill -USR1 "$pid" > /dev/null 2>&1
	;;
    *)
	echo "Usage: $0 [load|unload|start|stop|restart|status|reload|try-start]" >&2
	exit 1
	;;
esac
