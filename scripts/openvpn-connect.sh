#!/bin/sh -e -x

port=$1
proto=$2

# Create TUN interface
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

cat > client.ovpn <<EOF
client
tls-client

proto $proto
dev tun
dev-type tun
remote $(getent hosts server | cut -f1 -d' ') $port $proto

resolv-retry infinite
keepalive 10 120

ca /app/keys/ca.crt
cert /app/keys/client.crt
key /app/keys/client.key
tls-auth /app/keys/ta.key 1

cipher AES-256-CBC
data-ciphers AES-256-CBC
auth SHA1
remote-cert-tls server

nobind
persist-key
persist-tun
EOF

openvpn --config client.ovpn &

sh -e -x /app/client.sh "10.0.0.1"
