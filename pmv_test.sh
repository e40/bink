#! /bin/bash

set -eu
set -o pipefail

prog="$(basename "$0")"

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog non-existent-directory-name

Test suite for bink/pmv.  The directory argument is created and removed.
EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

while [ $# -gt 0 ]; do
    case $1 in
        -*) usage unknown argument: $1 ;;
        *)  break ;;
    esac
    shift
done

[ $# -ne 1 ]   && usage wrong number of args
[ -e "$1" ]    && usage $1 should not exist
[[ $1 =~ / ]]  && usage contains / so it is not a dirctory name
[[ $1 =~ \s ]] && usage not a good idea if it contains spaces

d=$1

trap "/bin/rm -fr $d" EXIT

debug=

function d {
    if [ "$debug" ]; then
	echo "would: $*"
    else
	echo "+ $*"
        "$@"
    fi
}

files="1 2 3 4 5"

mkdir -p $d/xx $d/yy

for f in $files; do echo date > $d/xx/$f; done

touch -m --date=@1461920000 $d/xx/1
touch -m --date=@1461900000 $d/xx/2
touch -m --date=@1461000000 $d/xx/3 
touch -m --date=@1460000000 $d/xx/4
touch -m --date=@1400000000 $d/xx/5 

# Make the atime one year in the future
# That is, add this number of seconds to the mtime:
constant=$(( 24 * 3600 * 365 ))
for f in 1 2 3 4 5; do
    modifytime=$(stat --format='%Y' "$d/xx/$f")
    time=$(( modifytime + constant ))
    touch -a --date="@${time}" "$d/xx/$f"
done

# Usage: show_times dir
function show_times {
    local when=$1; shift
    echo ""
    echo "==================== $when ==========================="
    echo ""
    echo ========= Modify times:
    stat --printf='\n%y %n' $1/*
    echo ""

    echo ""
    echo ========= Access times:
    stat --printf='\n%x %n' $1/*
    echo ""

    echo ""
}

cat <<EOF
The access times on files before/after the pmv should be exactly
one year apart.
EOF

show_times "before" $d/xx

d $HOME/bink/pmv $d/xx/* $d/yy

show_times "after" $d/yy
