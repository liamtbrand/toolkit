# Helper functions for tools and scripts

abort_to_shell () {
	echo "Error: $1. Dropping to interactive shell..."
	PS1="[RECOVERY-MODE] \w \$ " bash -i
	exit 1
}

directory_is_inaccessible () {
	dir="$1"
	if ! (cd "$dir" 2>/dev/null) ; then
		return 0
	else
		return 1
	fi
}

# Asks yes or no in the prompt
# Returns true if the user answers yes
# Returns false if the user answers no
ask_yes_no () {
	while true; do
		# Note: /dev/tty redirect important:
		# This could be inside another read while loop...
		read -r -p "$1 [y/n]: " yn < /dev/tty
		case $yn in
			[Yy][Ee][Ss]|[Yy] ) return 0;;
			[Nn][Oo]|[Nn] ) return 1;;
			*) echo "Please answer yes or no.";;
		esac
	done
}

# Get the parent of a directory
parent_of () {
	dir="$1"
	echo "$(dirname -- "$dir")"
}

_drop_to_shell () {
	path="$1"
	cd "$path"
	exec bash --login
}

_offer_drop_to_shell () {
	path="$1"
	if ask_yes_no "Do you want to drop to shell at $path ?" ; then
		_drop_to_shell "$path"
	fi
}

_drop_to_interactive_subshell () {
	path="$1"
	echo "Dropping you into an interactive subshell at $path."
	echo "When you're finished exploring, type: exit"
	cd "$path"
	PS1="(subshell) \w \$ " $SHELL -i || true
	echo "Aborting parent script. This is for sanity."
	exit 0
}

_offer_drop_to_interactive_subshell () {
	path="$1"
	if ask_yes_no "Do you want to drop to an interactive subshell at $path ?" ; then
		_drop_to_interactive_subshell "$path"
	fi
}

