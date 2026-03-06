#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/assert_macos.sh"

TARGET="${1:-localhost}"
START_PORT="${2:-1}"
END_PORT="${3:-65535}"

echo "Port scan script for scanning TCP ports."
echo "Defaults to localhost. You can specify the target like: scan_tcp_ports.sh <ip> <startport> <endport>"

echo "Scanning $TARGET ports $START_PORT to $END_PORT..."

for port in $(seq $START_PORT $END_PORT); do
	(nc -zv -w1 -G1 $TARGET $port 2>&1 | grep "succeeded" && echo "Port $port is OPEN") &
done

wait

echo "Scan complete."
