#!/bin/sh -e -x

sleep 1 # Sometimes entities are not available immediately
server_ip=$(getent hosts server | cut -f1 -d' ')
client_ip=$(getent hosts client | cut -f1 -d' ')

cp -r /app/keys/* -t /etc/ipsec.d
ip route add "$client_ip" via "$client_ip" dev eth0 table 220 proto static src "$server_ip"

# Configure IPsec
cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev2

conn host-host
    left=$server_ip
    leftcert=server-cert.pem
    leftid=@server
    leftfirewall=yes
    right=$client_ip
    rightid=@client
    auto=add
EOF

cat > /etc/ipsec.secrets <<EOF
: RSA "server-key.pem"
EOF

ipsec start --nofork &

trap "exit" EXIT HUP INT TERM

while true; do
    iperf3 -J -s --json-stream
    sleep 5
done
