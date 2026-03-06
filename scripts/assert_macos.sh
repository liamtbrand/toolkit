#!/usr/bin/env bash
set -euo pipefail

OS_NAME=$(uname -s)
if [ "$OS_NAME" != "Darwin" ]; then
	echo "Script only supports MacOS"
	exit 1
fi

