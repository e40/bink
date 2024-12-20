#! /usr/bin/env bash

diskutil=/usr/sbin/diskutil

set -ueE -o pipefail
shopt -s nocasematch

prog="$(basename "$0")"

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

tempfile="/tmp/${prog}temp1$$"
rm -f "$tempfile"
# shellcheck disable=SC2317
function exit_cleanup {
    rm -f "$tempfile"
}
# shellcheck disable=SC2317
function err_report {
    echo "Error on line $(caller)" 1>&2
}
trap err_report   ERR
trap exit_cleanup EXIT

function notify {
    echo "$*" | Mail -s "$0" "${ALERT_EMAIL}"
}

{
    if [ "$(uname -s)" != Darwin ]; then
        errordie "this script is macOS only"
    fi
    if [ ! "${ALERT_EMAIL-}" ]; then
        errordie ALERT_EMAIL is not defined
    fi
    disks=()
    $diskutil list | grep -E '^/dev/disk.*physical'  > "$tempfile"
    while IFS=$'\n' read -r line; do
        if [[ $line =~ ^/dev/(disk[0-9]+)[[:space:]] ]]; then
            disk=${BASH_REMATCH[1]}
            if $diskutil info "$disk" | grep -qE 'SMART Status:.*Not Supported'
            then
                : #echo "$disk does not support SMART status"
            else
                disks+=("$disk")
            fi
        else
            errordie "no match: $line"
        fi
    done <<< "$(cat "$tempfile")"

    # Iterate over the disks which support SMART status

    for disk in "${disks[@]}"; do
        if $diskutil info "$disk" | grep -qE 'SMART Status:.*Verified'; then
            : #notify "NOTE: $(hostname -s): $disk is healthy"
        else
            notify "WARNING: $(hostname -s): $disk is NOT healthy"
        fi
    done

    exit 0
}
