#! /bin/bash
# Usage: m command
#  the output of command is mailed to the email address in ~/.alert.email

set -eu

alert=$HOME/.alert.email

if [ ! -f $alert ]; then
    echo $HOME/.alert.emacs does not exist.
    exit 1
fi

TO="$(cat $alert)"

logfile=/tmp/temp$$
rm -f $logfile

exec &> >(tee $logfile)

status=

function send_report {
    Mail -s "$(basename $0): $status" $TO < $logfile || true
    rm -f $logfile
}

trap send_report EXIT

if "$@"; then
    status=SUCCESS
else
    status=FAILURE
fi
