#!/bin/sh

# Automated synchronisation of data
#
# Problem:
# I use multiple machines which house important data.
# This data varies between volatile and non-volatile.
# I store non-volatile data in an annex.
# I store volatile data in project folders and git repositories.
# This data needs to be synced between machines and backed up on a regular basis.
#
# Solution: autosync
#
# Automatically issue synchronisation commands using scripts
# Define policy for moving data around and use the scripts to accomplish it.
# Reduce manual involvement when synchronising data.

__private_autosync_repos() {

}

__private_autosync_annex() {
	
}

autosync () {
	echo "Autosync tool. Not yet implemented."
	echo "Keep your data and digital life in sync."
}
