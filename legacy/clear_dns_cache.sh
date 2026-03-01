#!/usr/bin/env bash
set -euo pipefail

UNAME=$(uname)

if [ "$UNAME" == "Darwin" ] ; then
	echo "Darwin"
	sudo dscacheutil -flushcache
	sudo killall -HUP mDNSResponder
else
	echo "Unknown system."
fi
