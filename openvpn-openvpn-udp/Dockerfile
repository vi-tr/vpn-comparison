FROM ubuntu:25.04

EXPOSE 1194/udp

RUN apt-get update && \
    apt-get install -y iperf3 tcpdump iproute2 jq openvpn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY openvpn-server.sh /app/server.sh
COPY openvpn-connect.sh /app/connect.sh
COPY client.sh /app/client.sh
