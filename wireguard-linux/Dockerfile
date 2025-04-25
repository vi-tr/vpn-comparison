FROM ubuntu:25.04

EXPOSE 51820/udp

RUN apt-get update && \
    apt-get install -y iperf3 tcpdump iproute2 jq wireguard wireguard-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY wireguard-linux-server.sh /app/server.sh
COPY wireguard-linux-connect.sh /app/connect.sh
COPY client.sh /app/client.sh
