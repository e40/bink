#! /usr/bin/env bash

set -ueE -o pipefail

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [--debug] output-directory

Output all saved images to OUTPUT-DIRECTORY (in tar format).
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

if ! type -p docker > /dev/null; then
    errordie "Cannot find docker, please install it before running $prog"
fi

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

while [ $# -gt 0 ]; do
    case $1 in
        --debug) debug=$1 ;;
        --) ;;
        *)  break ;;
    esac
    shift
done

[ $# -eq 1 ] || usage "expected 1 argument"

output=$1

[ -d "$output" ] || errordie "$output is not an existing directory"

lockfile="/tmp/${prog}.lock"

# ensure that only one copy of this script is running at any given time
lockfile -r 0 "$lockfile" || errordie program is already running

# shellcheck disable=SC2317
function exit_cleanup {
    rm -f "$lockfile"
}
# shellcheck disable=SC2317
function err_report {
    echo "Error on line $(caller)" 1>&2
}
trap err_report   ERR
trap exit_cleanup EXIT

{
    for c in $(docker ps -a -q); do
        img=$(docker inspect --format='{{.Config.Image}}' "$c")
        safeimg=$(echo "$img" | tr '/:' '_')
        d docker save --output "$output/${safeimg}.tar" "$img"
    done
    exit 0
}
