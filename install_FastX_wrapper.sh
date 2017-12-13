#! /usr/bin/env bash
# Install a wrapper for /Applications/FastX.app that
# 1. allows FastX to be started from the macOS Dock, and
# 2. initializes environment variables so that my SSH agent will be used.
#
# Thanks to
# https://stackoverflow.com/questions/829749/launch-mac-eclipse-with-environment-variables-set
# for the idea on editing the Info.plist and running lsregister.
# Thanks to
# https://stackoverflow.com/questions/36111323/in-plist-files-how-to-extract-string-text-after-unique-key-tag-via-xmlstarlet-to
# for crucial info on using xmlstarlet to edit the Info.plist.

# Tested on macOS 10.12.6.
# Depends on: xmlstarlet (available in macports).

set -eu

# The file to source to make the SSH agent available.  This file was
# generated with
#   $ ssh-agent -s > $HOME/tmp/agent.info
agentinfo="$HOME/tmp/agent.info"

appdir="/Applications/FastX.app"

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

function die {
    [ "${*-}" ] && echo "$0: $*" 1>&2
    exit 1
}

[ -d "$appdir" ] || die $appdir does not exist
[ -x "$lsregister" ] || die cannot find lsregister

path="$appdir/Contents/MacOS"
script="$path/FastX.sh"
plist="$appdir/Contents/Info.plist"

wraptmp=/tmp/tempA$$
plisttmp=/tmp/tempB$$
rm -f $wraptmp $plisttmp
trap "/bin/rm -f $wraptmp $plisttmp" 0

cat > $wraptmp <<EOF
#! /usr/bin/env bash

[ -f "$agentinfo" ] && source "$agentinfo"

logger "$path/FastX"

exec "$path/FastX" "\$@"
EOF

chmod +x $wraptmp
sudo mv $wraptmp "$script"

xmlstarlet \
    ed -u \
    '//key[.="CFBundleExecutable"]/following-sibling::string[1]' \
    -v "$(basename $script)" \
    < $plist > $plisttmp

[ -f ${plist}.orig ] || sudo mv $plist ${plist}.orig
sudo mv $plisttmp $plist

$lsregister -v -f "$appdir"
