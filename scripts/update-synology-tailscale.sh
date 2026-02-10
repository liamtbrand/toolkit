#!/bin/sh

# Update tailscale on synology nas

if [ ! -f /usr/syno/bin/synopkg ]; then
	echo "This script can only be run on a Synology NAS."
	exit 1
fi

tailscale update --yes
