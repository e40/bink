#! /usr/bin/env bash
# shellcheck disable=SC1091,SC2129

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

  top_sticky=("...")

  bottom_sticky=("...")

Running $prog will print one of these lines, randomly chosen.

If "top_sticky" and/or "bottom_sticky" are not the null array, then
print "top_sticky" before the randomly chosen line above, and
"bottom_sticky" after it.  They are constants for every run.
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
        -*) usage "unknown argument: $1" ;;
        *)  break
	    ;;
    esac
    shift
done

[ $# -gt 1 ] && usage expected 0 or 1 args got $#

address="${1-}"

source "$HOME/.motd"

tempfile=/tmp/temp$$
rm -f $tempfile
trap "/bin/rm -f $tempfile" EXIT

n=$(shuf --input-range=0-$(( ${#motd[@]} - 1 )) -n 1)

if [ ${#top_sticky[@]} -gt 0 ]; then
    echo "${top_sticky[0]}"     >> $tempfile
    echo ""                     >> $tempfile
    echo "--------------------" >> $tempfile
    echo ""                     >> $tempfile
fi
echo "${motd[$n]}"          >> $tempfile
if [ ${#bottom_sticky[@]} -gt 0 ]; then
    echo ""                     >> $tempfile
    echo "--------------------" >> $tempfile
    echo ""                     >> $tempfile
    echo "${bottom_sticky[0]}"  >> $tempfile
fi

if [ "$address" ]; then
    Mail -s "$subject" "$address" < "$tempfile"
else
    cat $tempfile
fi
