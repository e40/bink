#! /usr/bin/env bash
# Install a wrapper for an app in /Applications/<name>.app that
# 1. allows the app to be started from the macOS Dock, and
# 2. initializes environment variables so that my SSH agent will be
#    used by the app's process.
#
# Thanks to
# https://stackoverflow.com/questions/829749/launch-mac-eclipse-with-environment-variables-set
# for the idea on editing the Info.plist and running lsregister.
# Thanks to
# https://stackoverflow.com/questions/36111323/in-plist-files-how-to-extract-string-text-after-unique-key-tag-via-xmlstarlet-to
# for crucial info on using xmlstarlet to trivially edit the Info.plist.

# Tested on macOS 10.12.6.

set -eu

prog=$(basename $0)

function usage {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    cat 1>&2 <<EOF
Usage: $prog [-f] appname

Wrap /Applications/APPNAME.app with a shell script that initializes an
SSH agent for use by APPNAME.

-f      :: means force the use of an SSH agent (if available),
           otherwise only start it if the env evar AGENT_WRAPPER_USE_AGENT
	   has a value other than null.

EOF
    exit 1
}

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

debug=
appname=
force=

while [ $# -gt 0 ]; do
    case $1 in
	--debug) debug=$1 ;;
	-f) force=$1 ;;
	-*) usage bad argument: $1 ;;
	*)  [ $# -gt 1 ] && usage too many args: $*
	    if [[ "$1" =~ (.*)\.app$ ]]; then
		appname="${BASH_REMATCH[1]}"
	    else
		appname="$1"
	    fi
	    ;;
    esac
    shift
done

function d {
    echo "+ $*" 1>&2
    if [ ! "$debug" ]; then
	"$@"
    fi
}

# The file to source to make the SSH agent available.  This file was
# generated with
#   $ ssh-agent -s > $HOME/tmp/agent.info
agentinfo="$HOME/tmp/agent.info"

appdir="/Applications/${appname}.app"

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

[ -d "$appdir" ] || errordie $appdir does not exist
[ -x "$lsregister" ] || errordie cannot find lsregister

path="$appdir/Contents/MacOS"
appexe="$path/${appname}"
appexereal="$path/${appname}.real"
plist="$appdir/Contents/Info.plist"

wraptmp=/tmp/tempA$$
plisttmp=/tmp/tempB$$
rm -f $wraptmp $plisttmp
trap "/bin/rm -f $wraptmp $plisttmp" 0

#### Move the real app aside
if [ ! -e "$appexereal" ]; then
    d sudo mv "$appexe" "$appexereal"
fi

#### Create the wrapper
cat > $wraptmp <<EOF
#! /usr/bin/env bash

if [ "$force" ] && [ -f "$agentinfo" ]; then
    source "$agentinfo"
elif [ "\${AGENT_WRAPPER_USE_AGENT-}" ] && [ -f "$agentinfo" ]; then
    source "$agentinfo"
fi
logger "$path/$appname"
exec "$appexereal" "\$@"
EOF
d chmod +x $wraptmp

#### Install the wrapper
d sudo mv $wraptmp "$appexe"

exit 0
###############################################################################
# No longer necessary, since now the original path is used for the wrapper.
# Code left in because it took me a good while to figure it out!
# If this code is used again, move this comment to the top of the file:
#     Depends on: xmlstarlet (I use the macports version)

type -p xmlstarlet > /dev/null || errordie xmlstarlet not installed

d xmlstarlet \
    ed -u \
    '//key[.="CFBundleExecutable"]/following-sibling::string[1]' \
    -v "$(basename $script)" \
    < $plist > $plisttmp
[ -f ${plist}.orig ] || d sudo mv $plist ${plist}.orig
d sudo mv $plisttmp $plist
d $lsregister -v -f "$appdir"
