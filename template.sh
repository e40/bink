#! /usr/bin/env bash
# <blah blah blah>

set -eu
set -o pipefail
# have case and [[ do case-insensitive matches
shopt -s nocasematch

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [--switch1] [--switch2 blah]

blah blah blah fix me blah blah blah
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

debug=
file=

while [ $# -gt 0 ]; do
    case $1 in
        --debug) debug=$1 ;;
        --file)
	    [ $# -ge 2 ] || usage $1: missing companion argument 
            shift
            file="$1"
            ;;
        -*) usage unknown argument: $1 ;;
        *)  usage extra args: $*
	    ##or, choose this if extra arg processing down below
	    #break
	    ;;
    esac
    shift
done

[ $# -eq 2 ] || echo do this for the 2 arg case

function d {
    if [ "$debug" ]; then
	echo "would: $*"
    else
	echo "+ $*"
        "$@"
    fi
}

# main body is in a list so the script can be changed while in use
{
    lockfile="/tmp/${prog}.lock"
    tempfile="/tmp/${prog}temp$$"
    rm -f $tempfile 
    trap "/bin/rm -f $tempfile $lockfile" EXIT

    # ensure that only one copy of this script is running at any given time
    lockfile -r 0 $lockfile || errordie $prog is already running

    find ... > $tempfile
    while read line; do
	# this stuff happens in the same shell as the main script
    done <<< "$(cat "$tempfile")"

    find ... |
	while read line; do
	    # this stuff happens in a subshell and can't modify variables above
	done

    ...

    exit 0
}
