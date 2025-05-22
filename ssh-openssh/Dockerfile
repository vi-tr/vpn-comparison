FROM ubuntu:25.04

EXPOSE 22/tcp

RUN apt-get update && \
    apt-get install -y iperf3 tcpdump iproute2 jq openssh-server openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY openssh-server.sh /app/server.sh
COPY openssh-connect.sh /app/connect.sh
COPY client.sh /app/client.sh
