#! /usr/bin/env bash
# Install a wrapper for FastX that initializes environment variables
# for my SSH agent.

set -eu

if [ -e /fi/scm/bin/scm.subs ]; then
    source /fi/scm/bin/scm.subs
elif [ -e $HOME/scm-bin/scm.subs ]; then
    source $HOME/scm-bin/scm.subs
else
    echo $0: cannot find scm.subs 1>&2
    exit 1
fi

appdir="/Applications/FastX.app"

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

[ -d "$appdir" ] || die $appdir does not exist
[ -x "$lsregister" ] || die cannot find lsregister

path="$appdir/Contents/MacOS"
script="$path/FastX.sh"
plist="$appdir/Contents/Info.plist"

wraptmp=/tmp/tempA$$
plisttmp=/tmp/tempB$$
rm -f $wraptmp $plisttmp
trap "/bin/rm -f $wraptmp $plisttmp" 0

agentinfo="$HOME/tmp/agent.info"

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
