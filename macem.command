#! /usr/bin/env bash

if macem=$(type -p macem); then
    :
else
    error "Could not find 'macem' script."
    exit 1
fi

exec "$macem"
