#!/bin/sh -e -x

sleep 1 # Sometimes entities are not available immediately
server_ip=$(getent hosts server | cut -f1 -d' ')
client_ip=$(getent hosts client | cut -f1 -d' ')

cp -r /app/keys/* -t /etc/ipsec.d
ip route add "$server_ip" via "$server_ip" dev eth0 table 220 proto static src "$client_ip"

# Configure IPsec
cat > /etc/ipsec.conf <<EOF
config setup
    uniqueids=no

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev2

conn host-host
    left=$client_ip
    leftcert=client-cert.pem
    leftid=@client
    leftfirewall=yes
    right=$server_ip
    rightid=@server
    auto=start
EOF

cat > /etc/ipsec.secrets <<EOF
client : RSA "client-key.pem"
EOF

ipsec start --nofork &

sh -e -x /app/client.sh "$server_ip"
