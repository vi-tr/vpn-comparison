#!/bin/sh -e

if [ ! $(command -v ssh-keygen) ]; then
    echo "OpenSSH is required to generate keys for containers!"
    exit 1
fi

wpath=$(dirname $(realpath $(command -v $0)))
mkdir -p "$wpath/keys"
cd "$wpath"

ssh-keygen -t ed25519 -f keys/server_key -N "" -C server_key
ssh-keygen -t ed25519 -f keys/client_key -N "" -C client_key
