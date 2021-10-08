#! /usr/bin/env bash
#
# setup:
#  this is optional:
#    git remote add gitlab git@gitlab.com:e40/bink.git
# empire:
#  git remote add local figit:/repo/users/git.layer/bink

set -ue -o pipefail

prog="$(basename "$0")"

function errordie {
    [ "${*-}" ] && echo "$prog: $*" 1>&2
    exit 1
}

function d {
    echo "+ $*"
    "$@"
}

git remote get-url local &> /dev/null || errordie local remote not defined
git remote get-url origin &> /dev/null || errordie local remote not defined

origin=$(git remote get-url origin)
local=$(git remote get-url local)

[[ $local =~ ^git:/ ]] || errordie local remote is not local
[[ $origin =~ github ]] || errordie origin remote is not to github

{
    # If the rebase fails, then the script will stop, so this is safe
    d git pull -r

    d git push origin master

    d git push local master

    if git remote get-url gitlab &> /dev/null; then
        d git push gitlab master
    fi

    # Only remove the /net/$host prefix is $PWD doesn't have it
    if [[ $HOME =~ /net/[a-zA-Z0-9]+(/.*) ]]; then
        temp=${BASH_REMATCH[1]}
        if [[ ! $PWD =~ ^/net ]]; then
            home=$temp
        else
            home=$HOME
        fi
    else
        home=$HOME
    fi

    d onall -d ${PWD##$home/} git pull -r

    exit 0
}
