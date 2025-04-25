#!/bin/sh -e -x

cat <<EOL > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
PrivateKey = $(cat /app/keys/server-private.key)
ListenPort = 51820

[Peer]
PublicKey = $(cat /app/keys/client-public.key)
AllowedIPs = 10.0.0.0/24
EOL

wg-quick up wg0

trap "exit" EXIT HUP INT TERM

while true; do
    iperf3 -J -s --json-stream
    sleep 5
done
