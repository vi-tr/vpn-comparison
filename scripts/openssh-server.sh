#!/bin/sh -e -x

# Create TUN interface
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Set up interface
ip tuntap add dev tun0 mode tun user root
ip addr add 10.0.0.1/24 dev tun0
ip link set dev tun0 up

mkdir -p /etc/ssh /root/.ssh

cp -u /app/keys/client_key.pub /root/.ssh/authorized_keys

rm -f /etc/ssh/ssh_host_*_key*
cp /app/keys/server_key     /etc/ssh/ssh_host_ed25519_key
cp /app/keys/server_key.pub /etc/ssh/ssh_host_ed25519_key.pub
chown root:root -R /etc/ssh
chmod 600 /etc/ssh/ssh_host_*_key*

cat > /etc/ssh/sshd_config <<EOF
AuthorizedKeysFile .ssh/authorized_keys
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
PermitTunnel point-to-point
EOF

/usr/sbin/sshd -D &

trap "exit" EXIT HUP INT TERM

while true; do
    iperf3 -J -s --json-stream
    sleep 5
done
