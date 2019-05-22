#! /usr/bin/env bash

set -eu
set -o pipefail

prog="$(basename "$0")"

subject=MOTD

function usage {
    [ "${*-}" ] && echo "$prog: Error: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [-s subject] [address]

Print a message of the day, defined in the file ~/.motd.

If ADDRESS is given, then email it to that address.  If SUBJECT is
given, use that as the subject for the email, otherwise use
\"$subject\".

The contents of ~/.motd would something like this:

  motd=(

  "message 1"
  "message 2"
  "message 3"
  ...
  "message N"
  )

Running $prog will print one of these lines, randomly chosen.
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

type -p shuf > /dev/null || errordie cannot find shuf program

while [ $# -gt 0 ]; do
    case $1 in
	-s) [ $# -ge 2 ] || usage -s: missing companion argument 
	    shift
	    subject=$1
	    ;;
        -*) usage unknown argument: $1 ;;
        *)  break
	    ;;
    esac
    shift
done

[ $# -gt 1 ] && usage expected 0 or 1 args got $#

address="${1-}"

source $HOME/.motd

n=$(shuf --input-range=0-$(( ${#motd[@]} - 1 )) -n 1)

if [ "$address" ]; then
    echo "${motd[$n]}" | Mail -s "$subject" $address
else
    echo "${motd[$n]}"
fi

