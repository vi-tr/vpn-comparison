FROM ubuntu:25.04

EXPOSE 5201

RUN apt-get update && \
    apt-get install -y iperf3 tcpdump iproute2 jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY client.sh /app/client.sh
