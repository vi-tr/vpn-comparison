#!/bin/sh -e -x

port=$1
proto=$2

# Create TUN interface
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Per-client config
mkdir -p /etc/openvpn/ccd
echo "ifconfig-push 10.0.0.2 255.255.255.0" > /etc/openvpn/ccd/client

cat > /etc/openvpn/server.conf <<EOF
mode server
tls-server

port $port
proto $proto
dev tun
dev-type tun
server 10.0.0.0 255.255.255.0
ifconfig 10.0.0.1 255.255.255.0

keepalive 10 120

ca /app/keys/ca.crt
cert /app/keys/server.crt
key /app/keys/server.key
dh /app/keys/dh.pem
tls-auth /app/keys/ta.key 0

cipher AES-256-CBC
data-ciphers AES-256-CBC

persist-key
persist-tun

user nobody
group nogroup
EOF

openvpn --config /etc/openvpn/server.conf &

trap "exit" EXIT HUP INT TERM

while true; do
    iperf3 -J -s --json-stream
    sleep 5
done
