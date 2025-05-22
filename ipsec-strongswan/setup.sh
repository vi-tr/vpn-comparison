#!/bin/sh -e

wpath=$(dirname $(realpath $(command -v $0)))

if [ ! $(command -v pki) ]; then
    echo "StrongSwan is required to generate keys for the containers!"
    exit 1
fi

mkdir -p "$wpath/keys/cacerts" "$wpath/keys/certs" "$wpath/keys/private"
cd "$wpath/keys"

# CA
pki --gen --type rsa --size 4096 --outform pem > private/ca-key.pem
pki --self --ca --lifetime 3650 --in private/ca-key.pem \
    --type rsa --dn "CN=CA" --outform pem > cacerts/ca-cert.pem

# Server
pki --gen --type rsa --size 4096 --outform pem > private/server-key.pem
pki --pub --in private/server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=server" --san server \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  certs/server-cert.pem

# Client
pki --gen --type rsa --size 4096 --outform pem > private/client-key.pem
pki --pub --in private/client-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=client" --san client \
        --flag clientAuth --flag ikeIntermediate --outform pem \
    >  certs/client-cert.pem
