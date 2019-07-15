#! /usr/bin/env bash

set -eu
set -o pipefail

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog

TURN OFF SPOTLIGHT.  That is all.
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

debug=

while [ $# -gt 0 ]; do
    case $1 in
        --debug) debug=$1 ;;
        *)       usage unknown argument: $1 ;;
    esac
    shift
done

function d {
    if [ "$debug" ]; then
	echo "would: $*"
    else
	echo "+ $*"
        "$@"
    fi
}

{
    for localfs in $(df --output=target -l | tail -n +2); do
	# This always gives errors:
	[[ $localfs =~ /private/var/vm ]] && continue

	d sudo mdutil -i off $localfs
	d sudo mdutil -X     $localfs
    done

    exit 0
}
