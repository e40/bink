#! /usr/bin/env bash

set -eu
set -o pipefail

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [-s subject] [-t addresses] command...

The output of 'command' is mailed to:
 1. the given 'addresses', or
 2. the value of \$ALERT_EMAIL from the environment
 3. if it exists, the contents of the file \$HOME/.alert.email

If neither of the above conditions are met, then the output
is sent to stdout.

The default subject of "(SUCCESS|FAILURE): command..." can be
changed with the -s command line argument.

Send no mail when there is no output.
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

alertfile=$HOME/.alert.email

if [ "${ALERT_EMAIL-}" ]; then
    to=${ALERT_EMAIL}
elif [ -f "$alertfile" ]; then
    to="$(cat $alert)"
else
    to=
fi

subject=

while [ $# -gt 0 ]; do
    case $1 in
        -s) [ $# -ge 2 ] || usage $1: missing companion argument 
            shift
            subject="$1"
            ;;
        -t) [ $# -ge 2 ] || usage $1: missing companion argument 
            shift
            to="$1"
            ;;
        *)  break ;;
    esac
    shift
done

status=
tempfile=/tmp/temp$$

command="$*"

function process_output {
    local s="${subject-$status: $command}"
    if [ ! -s $tempfile ]; then
	: # don't do anything
    elif [ "$to" ]; then
	Mail -s "$s" $to < $tempfile || true
    else
	cat $tempfile
    fi
    rm -f $tempfile
}

rm -f $tempfile
trap process_output EXIT

if ! exec &> $tempfile; then
    errordie redirection failed
fi

if "$@"; then
    status=SUCCESS
    exit 0
else
    status=FAILURE
    exit 1
fi
