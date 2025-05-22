FROM ubuntu:25.04

EXPOSE 500/udp
EXPOSE 4500/udp

RUN apt-get update && \
    apt-get install -y iperf3 tcpdump iproute2 jq strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY strongswan-server.sh /app/server.sh
COPY strongswan-connect.sh /app/connect.sh
COPY client.sh /app/client.sh
