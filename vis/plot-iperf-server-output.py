import argparse
import json
from itertools import zip_longest
from typing import Iterator

import matplotlib.pyplot as plt

# Helper functions


def zip_left(x: list, y: list, fillvalue=None) -> Iterator[tuple]:
    if len(x) > len(y):
        return zip_longest(x, y, fillvalue=fillvalue)
    return zip(x, y)


def immutable_update(x: dict, y: dict) -> dict:
    t = x.copy()
    t.update(y)
    return t


def extract_intervals(file_path) -> list[list[dict]]:
    server_sums: list[list[dict]] = []
    client_sums: list[list[dict]] = [[]]

    with open(file_path) as file:
        for line in file:
            try:
                data: dict = json.loads(line)
                if data.get("event") == "server_output_json":
                    server_sums.append([x["sum"] for x in data["data"]["intervals"]])
                if data.get("event") == "interval":
                    client_sums[-1].extend(data["data"]["streams"])
                if data.get("event") == "end":
                    client_sums.append([])
            except json.JSONDecodeError:
                print(f"Error decoding JSON in line: {line.strip()}")

    intervals = [
        [immutable_update(w, z) for z, w in zip_left(x, y, fillvalue={})]
        for x, y in zip_left(server_sums, client_sums, fillvalue=[])
    ]
    return intervals


def get_data(interval: dict, kind: str) -> float | None:
    if kind == "bytes":
        return interval["bytes"] / 1_048_576
    elif kind == "lost":
        return interval.get("lost_packets") or interval.get("retransmits")
    elif kind == "lost-percentage":
        return interval.get("lost_percent")
    elif kind == "jitter":
        return interval.get("jitter_ms")
    elif kind == "rtt":
        if rtt := interval.get("rtt"):
            return rtt / 1000
        return None
    return interval["bits_per_second"] / 1_000_000


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Visualize data from iperf3 client+server NDJSON summaries."
    )
    parser.add_argument(
        "ndjson_file", type=str, nargs="+", help="Path to the ndjson file"
    )
    parser.add_argument("-f", "--main-title", type=str, help="Title of the figure")
    parser.add_argument(
        "-b",
        "--monochrome-printer",
        action="store_true",
        help="Use line styles instead of colors in plots",
    )
    parser.add_argument(
        "-t", "--title", type=str, nargs="+", help="Title for the plots"
    )
    parser.add_argument(
        "-s", "--single", action="store_true", help="Merge all runs into a single graph"
    )
    parser.add_argument(
        "-m",
        "--metric",
        type=str,
        default="bandwidth",
        help="Which metric to graph over time. One of: bandwidth, bytes, lost, lost-percentage (UDP only), jitter (UDP only), rtt (TCP only)",
    )
    args = parser.parse_args()

    plt.figure(figsize=(10, 5))
    if args.main_title:
        plt.title(args.main_title)

    plt.xlabel("Время (секунды)")

    if args.metric == "bandwidth":
        plt.ylabel("Пропускная способность (Mbps)")
    elif args.metric == "bytes":
        plt.ylabel("Размер переданных данных за промежуток (MiB)")
    elif args.metric == "lost":
        plt.ylabel("Количество потерянных пакетов")
    elif args.metric == "lost-percentage":
        plt.ylabel("Процент потерянных пакетов")
    elif args.metric == "jitter":
        plt.ylabel("Джиттер (мс)")
    elif args.metric == "rtt":
        plt.ylabel("Круговая задержка (мс)")

    linestylecounter = 0
    linestyles = ["solid", "dashed", "dashdot", "dotted", "solid", "dashed"]
    markers = ["none", "none", "none", "none", "x", "P"]

    for i, file in enumerate(args.ndjson_file):
        all_intervals = extract_intervals(file)
        if args.single:  # Concat runs
            data: list[float | None] = []
            starts: list[float] = []
            offset = 0
            for intervals in all_intervals:
                for interval in intervals:
                    start = interval["start"]
                    starts.append(start + offset)
                    data.append(get_data(interval, args.metric))
                offset += intervals[-1]["end"] + 3 if len(intervals) else 3
            if args.monochrome_printer:
                plt.plot(
                    starts,
                    # Matplotlib can plot lists with missing values just fine
                    data,  # type: ignore
                    label=args.title[i] if args.title and len(args.title) > i else file,
                    color="black",
                    linestyle=linestyles[linestylecounter % len(linestyles)],
                    marker=markers[linestylecounter % len(linestyles)],
                )
                linestylecounter += 1
            else:
                plt.plot(
                    starts,
                    # Matplotlib can plot lists with missing values just fine
                    data,  # type: ignore
                    label=args.title[i] if args.title and len(args.title) > i else file,
                )
        else:  # Plot different runs separately
            all_data: list[list[float | None]] = []
            all_starts: list[list[float]] = []
            for intervals in all_intervals:
                all_data.append(data := [])
                all_starts.append(starts := [])
                for interval in intervals:
                    start = interval["start"]
                    starts.append(start)
                    data.append(get_data(interval, args.metric))
            for j, (starts, data) in enumerate(zip(all_starts, all_data)):
                if args.monochrome_printer:
                    plt.plot(
                        starts,
                        data,  # type: ignore
                        label=f"{args.title[i] if args.title and len(args.title) > i else file} (забег {j+1})",
                        color="black",
                        linestyle=linestyles[linestylecounter % len(linestyles)],
                        marker=markers[linestylecounter % len(linestyles)],
                    )
                    linestylecounter += 1
                else:
                    plt.plot(
                        starts,
                        data,  # type: ignore
                        label=f"{args.title[i] if args.title and len(args.title) > i else file} (забег {j+1})",
                    )

    plt.legend(loc="upper right")
    plt.grid()
    plt.show()
