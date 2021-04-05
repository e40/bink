#! /usr/bin/env bash

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

    # execute it in remote directories in the same relative directory
    d onall -d ${PWD##$HOME/} git pull -r

    exit 0
}
