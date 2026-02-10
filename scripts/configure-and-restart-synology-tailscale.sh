#!/bin/sh

# Configure and restart synology tailscale
# Script indended to be run on boot
#
# This fixes the issue where tailscale cannot make outbound connections.
#
# Set up script in Task Scheduler to run using root account.
# Auto run the task on Boot Up.

if [ ! -f /usr/syno/bin/synopkg ]; then
	echo "This script can only be run on a Synology NAS."
	exit 1
fi

/var/packages/Tailscale/target/bin/tailscale configure-host;
synosystemctl restart pkgctl-Tailscale.service
