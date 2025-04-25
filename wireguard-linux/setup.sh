#!/bin/sh -e

if [ ! $(command -v wg) ]; then
    echo "WireGuard is required to generate keys for containers!"
    exit 1
fi

wpath=$(dirname $(realpath $(command -v $0)))
mkdir -p "$wpath/keys"
cd "$wpath"

wg genkey | tee keys/server-private.key | wg pubkey > keys/server-public.key
wg genkey | tee keys/client-private.key | wg pubkey > keys/client-public.key
