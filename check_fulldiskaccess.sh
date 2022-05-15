#! /usr/bin/env bash
# Make sure certain programs have Full Disk Access in
# System Preferences -> Security & Privacy.
#
# This script CANNOT grant access, just check that the access has
# been granted and warn if it has not.

# The database containing the programs
TCCdb='/Library/Application Support/com.apple.TCC/TCC.db'

declare -a fulldiskaccess
fulldiskaccess=(

    # Needed for shells inside Emacs, too
    "com.apple.Terminal"

    # Not sure this is strictly needed??
    "org.gnu.Emacs"

    # needed for Emacs to access the filesystem, because Emacs startup
    # is a Ruby script.
    "/usr/bin/ruby"
    )

set -ueE -o pipefail

prog="$(basename "$0")"

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

if ! type -p sqlite3 > /dev/null; then
    errordie sqlite3 is not installed
fi

if ! sudo file "$TCCdb" &> /dev/null; then
    errordie "$TCCdb: cannot access: grant Terminal FDA first"
fi

tempfile="/tmp/${prog}temp$$"
rm -f "$tempfile"
function exit_cleanup {
    /bin/rm -f "$tempfile"
}
function err_report {
    echo "Error on line $(caller)" 1>&2
}
trap err_report   ERR
trap exit_cleanup EXIT

function current_FDA_programs {
    sudo sqlite3 "$TCCdb" \
         'select client from access where auth_value and service = "kTCCServiceSystemPolicyAllFiles"'
}

{
    current_FDA_programs > "$tempfile"
    for bin in "${fulldiskaccess[@]}"; do
        if ! grep -q "$bin" "$tempfile"; then
            echo "$bin: does not access Full Disk Access"
        fi
    done
}
