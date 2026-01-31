#! /usr/bin/env bash

set -ueE -o pipefail

host=$(hostname -s)

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [-v]

Check that \$HOME/.crontab.${host} and "crontab -l" are the same, and
exit with a zero status if they are.  Otherwise, print the difference
and exit with a non-zero status.
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

verbose=

while [ $# -gt 0 ]; do
    case $1 in
        -v) verbose=$1 ;;
        *)  usage extra args: "$@" ;;
    esac
    shift
done

crontab="$HOME/.crontab.${host}"

[ -s "$crontab" ] || errordie "$crontab does not exist"

tempfile="/tmp/${prog}temp1$$"
tempfile2="/tmp/${prog}temp2$$"
rm -f "$tempfile" "$tempfile2"
# shellcheck disable=SC2317
function exit_cleanup {
    rm -f "$tempfile"
    rm -f "$tempfile2"
}
# shellcheck disable=SC2317
function err_report {
    echo "Error on line $(caller)" 1>&2
}
trap err_report   ERR
trap exit_cleanup EXIT

{

    if ! crontab -l > "$tempfile"; then
        errordie "crontab -l failed"
    fi

    if ! diff <(crontab -l) "$crontab" > "$tempfile2"; then
        echo "diff \"crontab -l\" $crontab:"
        cat "$tempfile2"
        errordie "crontab in use and the file are not the same"
    fi

    [ "$verbose" ] && echo Crontabs are the same
    exit 0
}
