#!/bin/sh -e -x

# Create TUN interface
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Setup interface
ip tuntap add dev tun0 mode tun user root
ip addr add 10.0.0.2/24 dev tun0
ip link set dev tun0 up

mkdir -p /etc/ssh /root/.ssh

echo "server $(cut -f1-2 -d' ' /app/keys/server_key.pub)" > /etc/ssh/ssh_known_hosts
cp -u /app/keys/client_key     /root/.ssh/id_ed25519
cp -u /app/keys/client_key.pub /root/.ssh/id_ed25519.pub
chown root:root -R /root/.ssh
chmod 600 /root/.ssh/id_*

while ! ssh -N -w 0:0 server; do
    echo "Reconnecting to ssh..."
done &

sh -e -x /app/client.sh 10.0.0.1
