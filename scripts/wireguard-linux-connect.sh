#!/bin/sh -e -x

cat <<EOL > /etc/wireguard/wg0-client.conf
[Interface]
PrivateKey = $(cat /app/keys/client-private.key)
Address = 10.0.0.2/24

[Peer]
PublicKey = $(cat /app/keys/server-public.key)
Endpoint = $(getent hosts server | cut -f1 -d' '):51820
AllowedIPs = 10.0.0.0/24
EOL

wg-quick up wg0-client

sh -e -x /app/client.sh "10.0.0.1"
