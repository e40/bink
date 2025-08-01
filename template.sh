#! /usr/bin/env bash
# <blah blah blah>

# -E allows -e to work with 'trap ... ERR'
set -ueE -o pipefail
# have case and [[ do case-insensitive matches
shopt -s nocasematch

prog="$(basename "$0")"

# SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# source ${SCRIPTDIR}/foo.subs

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

if ! TEMP=$(getopt --shell bash -o f: -l debug,file: -n "$prog" -- "$@"); then
    exit 1
fi

if ! type -p foo > /dev/null; then
    errordie "Cannot find foo, please install it before running $prog"
fi

eval set -- "$TEMP"

debug=

function d {
    local arg
    if [ "$debug" ]; then
	echo -n "would: " 1>&2
    else
	echo -n "+ " 1>&2
    fi
    for arg in "$@"; do
        if [[ "$arg" =~ [[:space:]] ]]; then
            printf '"%s" ' "$arg" 1>&2
        else
            printf '%s ' "$arg" 1>&2
        fi
    done
    echo ""
    if [ ! "$debug" ]; then
        "$@"
    fi
}

file=

while [ $# -gt 0 ]; do
    case $1 in
        --debug) debug=$1 ;;
        -f|--file)
	    [ $# -ge 2 ] || usage "$1: missing companion argument"
            shift
            file="$1"
            ;;
        --) ;;
        *)  usage extra args: "$@"
	    ##or, choose this if extra arg processing down below
	    #break
	    ;;
    esac
    shift
done

[ -f "$file" ] || errordie "$file" does not exist

[ $# -eq 2 ] && echo "do this for the 2 arg case"

lockfile="/tmp/${prog}.lock"

# ensure that only one copy of this script is running at any given time
lockfile -r 0 "$lockfile" || errordie program is already running

tempfile="/tmp/${prog}temp1$$"
tempfile2="/tmp/${prog}temp2$$"
rm -f "$tempfile"
rm -f "$tempfile2"
# shellcheck disable=SC2317
function exit_cleanup {
    rm -f "$tempfile"
    rm -f "$tempfile2"
    rm -f "$lockfile"
}
# shellcheck disable=SC2317
function err_report {
    echo "Error on line $(caller)" 1>&2
}
trap err_report   ERR
trap exit_cleanup EXIT

output="script.out"
# Send all output to $output AND stdout
exec &> >(tee -a "$output")
# Send all output to $output
exec &> "$output"

# main body is in a list so the script can be changed while in use
{
    find ... > "$tempfile"
    while IFS=$'\n' read -r line; do
	# this stuff happens in the same shell as the main script
        echo "$line"
    done <<< "$(cat "$tempfile")"

    find .. .. |
	while IFS='$\n' read -r line; do
	    # this stuff happens in a subshell and can't modify variables above
            echo "$line"
	done

    ...

    exit 0
}
