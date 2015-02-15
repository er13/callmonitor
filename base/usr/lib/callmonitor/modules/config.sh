#! /bin/ash
cfg_cat() {
    local allcfgconv_bin="allcfgconv"
    type -p allcfgconv-c >/dev/null 2>&1 && allcfgconv_bin="allcfgconv-c"
    if $allcfgconv_bin -? 2>&1 | grep -q " -c "; then
        $allcfgconv_bin -C "$1" -e -c -o -
    elif type -p decrypt-fritzos-cfg >/dev/null 2>&1; then
        allcfgconv -C "$1" -e    -o - | decrypt-fritzos-cfg
    else
        echo "Error: no password decryption method available" >&2
    fi
}
cfg_parse() {
    sed -ne '
	## trace nested elements in hold space
	/^[[:space:]]*[[:alnum:]][[:alnum:]_]* {/ {
	    s/^[[:space:]]*\([[:alnum:]][[:alnum:]_]*\).*/\1/; H; d
	}
	/^[[:space:]]*}[[:space:]]*$/ {
	    x; s/\(.*\)\n.*$/\1/; h; d
	}
        ## only single-line values for now
	/=.*;$/ {
	    ## append parents, swap, and clean up
	    G
	    s/^[[:space:]]*\(.*\)\n\n\(.*\)/\2\n\1/
	    s/\n/_/g
	    s/[[:space:]]*=[[:space:]]*/=/
	    s/[$`]/\\&/g
	    ## hack for arrays
	    s/ "/\\ "/g
	    p
	}
    '
}
cfg_top() {
    local pat="$1"
    sed -ne '/^'"$pat"'[[:space:]]*{/,/^}/p'
}
cfg() {
    case $# in
	2) cfg_cat "$1" | cfg_top "$2" | cfg_parse ;;
	1) cfg_cat "$1" | cfg_parse ;;
	*) return 1 ;;
    esac
}
case $0 in *cfg2sh) cfg "$@";; esac
