#! /usr/bin/env bash

diskutil=/usr/sbin/diskutil

# array of "model:temp" with temps in Celsius.
# I implemented this check because the current temp of my 24TB drive is
# fairly close to the max temp.  Well, 56C < 65C, but that _seems_ close.
maxtemps=(
    # WD 24TB operating temp: 65C (149F!)
    # This is directly from the WD data sheet for the drive.
    "WDC WD240KFGX-68CJNN0:65"

    # Seagate 10TB: operating temp: 70C!!
    "ST10000VN0008-2JJ101:70"

    # Seagate 24TB, operating temp: 65C!
    "ST24000NT002-3N1101:65"
)

set -ueE -o pipefail
shopt -s nocasematch

prog="$(basename "$0")"

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

if [ "$(uname -s)" != Darwin ]; then
    errordie "this script is macOS only"
fi

if ! type -p smartctl > /dev/null; then
    errordie "smartctl not installed, use Homebrew to install it"
fi

if [ ! "${ALERT_EMAIL-}" ]; then
    errordie ALERT_EMAIL is not defined
fi

verbose=
while [ $# -gt 0 ]; do
    case $1 in
        -v|--verbose) verbose=$1 ;;
        --)           ;;
        *)            usage "extra args: $*" ;;
    esac
    shift
done

tempfile="/tmp/${prog}temp1$$"
tempfile2="/tmp/${prog}temp2$$"
rm -f "$tempfile"
rm -f "$tempfile2"
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

function notify {
    if [ "$verbose" ]; then
        echo "$@"
    else
        echo "$*" | Mail -s "$0" "${ALERT_EMAIL}"
    fi
}

# usage: value_sans_leading_zero number
#   print NUMBER without the leading zero, if there is one
function value_sans_leading_zero {
    if [[ $1 =~ 0(.*) ]]; then
        echo ${BASH_REMATCH[1]}
    else
        echo $1
    fi
}

{
    disks=()
    $diskutil list | grep -E '^/dev/disk.*physical'  > "$tempfile"
    while IFS=$'\n' read -r line; do
        if [[ $line =~ ^/dev/(disk[0-9]+)[[:space:]] ]]; then
            disk=${BASH_REMATCH[1]}
            if $diskutil info "$disk" | grep -qE 'SMART Status:.*Not Supported'
            then
                [ "$verbose" ] && echo "$disk does not support SMART status"
            else
                [ "$verbose" ] && echo "$disk supports SMART status"
                disks+=("$disk")
            fi
        else
            errordie "no match: $line"
        fi
    done <<< "$(cat "$tempfile")"

    # Iterate over the disks which support SMART status

    for disk in "${disks[@]}"; do
        if $diskutil info "$disk" | grep -qE 'SMART Status:.*Verified'; then
            [ "$verbose" ] && notify "NOTE: $(hostname -s): $disk is healthy"
        else
            notify "WARNING: $(hostname -s): $disk is NOT healthy"
        fi

        # Can't get SMART details for disk0
        [ "$disk" = "disk0" ] && continue

        if ! smartctl -a "$disk" > "$tempfile"; then
            cat "$tempfile"
            errordie smartctl failed
        fi

        if ! grep 'Device Model' "$tempfile" > "$tempfile2"; then
            errordie "Could not get model for $disk from smartctl"
        fi
        model=$(cat "$tempfile2")
        if [[ $model =~ Device\ Model:[[:space:]]+(.*)$ ]]; then
            model=${BASH_REMATCH[1]}
            [ "$verbose" ] &&
                echo "$disk: model is: $model"

            for data in "${maxtemps[@]}"; do
                if [[ $data =~ ^(.*):(.*)$ ]]; then
                    mod=${BASH_REMATCH[1]}
                    max=${BASH_REMATCH[2]}
                else
                    errordie "could not parse: $data"
                fi
                if [ "$model" = "$mod" ]; then
                    [ "$verbose" ] &&
                        echo "   have max temp: $max"
                else
                    continue
                fi

                # get the live data
                if ! smartctl -a "$disk" | grep Temperature_Celsius > "$tempfile2"
                then
                    errordie "could not get live temp data"
                fi
                value="$(awk '{print $4}' < "$tempfile2")"
                worst="$(awk '{print $5}' < "$tempfile2")"
                # according to the spec the values are decimal, not octal
                # even though they have leading zeros.
                value=$(value_sans_leading_zero "$value")
                worst=$(value_sans_leading_zero "$worst")
                if [ "$value" -ge "$max" ]; then
                    notify "WARNING: current high temp: $value > $max"
                else
                    [ "$verbose" ] &&
                        echo "   current temp OK: $value < $max"
                fi
                # need a way to turn this off, since once it happens
                # it will be that way forever
                if [ "$worst" -ge "$max" ]; then
                    notify "WARNING: worst high temp: $worst > $max"
                else
                    [ "$verbose" ] &&
                        echo "   worst temp OK: $worst < $max"
                fi
            done
        fi

    done

    exit 0
}
