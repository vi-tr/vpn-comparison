#!/bin/sh -e -x

## Variables

SERVER_IP=$1

if [ ! -f "$DATA_PATH" ]; then
    echo "Structured data not found!"
    exit 1
fi

[ "$LOG_PATH" ] || LOG_PATH=/app/log
mkdir -p "$LOG_PATH"

[ "$TRIALS" ] || TRIALS=5

## Functions

configure_netem() {
    delay=$1
    jitter=$2
    p=$3 # Probability of transitioning into the bad state
    if [ "$jitter" -gt 0 ]; then
        tc qdisc change dev eth0 root netem \
            delay "${delay}ms" "${jitter}ms" distribution normal \
            loss gemodel "$p%"
    else
        tc qdisc change dev eth0 root netem \
            delay "${delay}ms" loss gemodel "$p%"
    fi
}

iperf_test() {
    proto=$1
    data=$2
    label=$3
    basecmd="iperf3 -J -c $SERVER_IP -b 100m -t 5s --json-stream --get-server-output"
    path="$LOG_PATH/iperf-$SOFTWARE-$label-$proto-$data.ndjson"
    printf "" > "$path"
    i=0
    while [ "$i" -lt "$TRIALS" ]; do
        opts=""
        case "$proto-$data" in
            udp-random) opts="-u" ;;
            tcp-structured) opts="-F $DATA_PATH" ;;
        esac

        sleep 2s # Give the server some time to finish
        while ! $basecmd $opts >> "$path"; do
            if [ "$(tail -n 2 "$path" \
                | jq -c 'select(.event == "error" and .data != "the server is busy running a test. try again later")')" ]; then
                echo "An unrecoverable error occured. Skipping test" >&2
                break
            fi
        done

        i=$((i+1))
    done
}

## Main script

tc qdisc add dev eth0 root netem

for delay in 10 500; do # ms
    for jitter in 0 250; do # ms
        for loss_p in 0 2.5; do # %
            configure_netem $delay $jitter $loss_p
            for proto in udp tcp; do
                for data in structured random; do
                    [ "$proto-$data" = "udp-structured" ] && continue # Unsupported by iperf3
                    label="${delay}ms-${jitter}ms-p$loss_p"
                    tcpdump -i eth0 -w "$LOG_PATH/tcpdump-$SOFTWARE-$label-$proto-$data.pcap.gz" &
                    tcpdump_pid=$!
                    iperf_test "$proto" "$data" "$label"
                    kill -TERM $tcpdump_pid
                done
            done
        done
    done
done
