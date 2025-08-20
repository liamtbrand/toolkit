#!/bin/sh
# Home Lab Administration Tool

# Ensure the current working directory is the same as the script.
#cd "$(dirname "$0")"

__private_homelab_get_hosts()
{
	cat ~/.ssh/config | grep "Host " | grep "rpi" | sed "s/Host//"
}

__private_homelab_show_help()
{
	echo "Welcome to the Home Lab administration tool."
	echo ""
	echo "Usage:"
	echo "homelab status   - Shows the status of known hosts."
	echo "homelab services - Shows the status of services."
	echo "homelab update   - Run update scripts on host machines."
	echo "homelab help     - Show this help information."
	echo ""
}

__private_homelab_check_hosts_are_reachable()
{
	for HOST in $(__private_homelab_get_hosts) ; do
		if nc -z -G 2 "$HOST" 22 &> /dev/null; then
			echo "✓ $HOST"
		else
			echo "✗ $HOST"
		fi
	done
}

__private_homelab_update_and_upgrade_raspberry_pis()
{
	HOSTS=$(__private_homelab_get_hosts)
	echo ""
	echo "This script will run 'sudo apt update && sudo apt upgrade' on each raspberry pi."
	echo ""

	for HOST in $HOSTS ; do
		echo "------------------------------------------------"
		echo "Connecting to: $HOST"
		echo "------------------------------------------------"
		ssh -o ConnectTimeout=2 $HOST "cat /run/motd.dynamic && sudo apt update && sudo apt upgrade"
	done
}

__private_homelab_services()
{
	case "$1" in
		"list")
			echo "No services yet."
			;;
		*)
			echo "Services command not recognised."
			;;
	esac
	
}

homelab() {

	if [ "$(uname)" != "Darwin" ]; then
		echo "WARNING: Tool can only run on MacOS."
		exit
	fi

	#if [ $# -eq 0 ] ; then
	#    show_help
	#fi

	# There is some kind of argument.
	# Switch on first option.

	case "$1" in

		"status")
			__private_homelab_check_hosts_are_reachable
			;;

		"services")
			__private_homelab_services "${@:2}"
			;;

		"update")
			__private_homelabe_update_and_upgrade_raspberry_pis
			;;

		"help")
			__private_homelab_show_help
			;;

		*)
			echo "Invalid option. See 'homelab help' for help."
			;;
	 esac
}
