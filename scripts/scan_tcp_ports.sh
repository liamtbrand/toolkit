#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/assert_macos.sh"

TARGET="$1"
START_PORT=1
END_PORT=65535

echo "Scanning $TARGET ports $START_PORT to $END_PORT..."

for port in $(seq $START_PORT $END_PORT); do
	(nc -zv -w1 -G1 $TARGET $port 2>&1 | grep "succeeded" && echo "Port $port is OPEN") &
done

wait

echo "Scan complete."
