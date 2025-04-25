#!/bin/sh -e

if [ ! $(command -v easyrsa) ]; then
    echo "EasyRSA is required to generate keys for the containers!"
    exit 1
fi
if [ ! $(command -v openvpn) ]; then
    echo "OpenVPN is required to generate HMAC key!"
    exit 1
fi

wpath=$(dirname $(realpath $(command -v $0)))
mkdir -p "$wpath/keys"
cd "$wpath"

[ -d "pki" ] || easyrsa init-pki
[ -f "pki/ca.crt" ] || easyrsa build-ca
easyrsa gen-req server nopass
easyrsa sign-req server server

easyrsa gen-req client nopass
easyrsa sign-req client client
easyrsa gen-dh

openvpn --genkey secret ta.key

cp pki/ca.crt keys
cp pki/issued/server.crt keys
cp pki/private/server.key keys
cp pki/issued/client.crt keys
cp pki/private/client.key keys
cp pki/dh.pem keys
mv ta.key keys
