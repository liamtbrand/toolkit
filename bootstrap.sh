#!/usr/bin/env bash

# To bootstrap the toolkit: ./bootstrap.sh

# Toolkit for doing work in the terminal.
# I want to be able to bootstrap installing this.

TOOLKIT_UPSTREAM_URL="git@github.com:liamtbrand/toolkit.git"

TOOLKIT_REPO_PATH="$HOME/toolkit"

# If there is no directory for toolkit, clone it.
if [ ! -d "$TOOLKIT_REPO_PATH" ] ; then
	echo "[toolkit]: toolkit not found at $TOOLKIT_REPO_PATH. cloning from upstream..."
	git clone "$TOOLKIT_UPSTREAM_URL" "$TOOLKIT_REPO_PATH"
else
	echo "[toolkit]: toolkit found at $TOOLKIT_REPO_PATH"
fi

# Ensure toolkit is in fact toolkit
if ! git -C "$TOOLKIT_REPO_PATH" rev-parse --git-dir >/dev/null 2>&1 ; then
	echo "[toolkit]: Error: $TOOLKIT_REPO_PATH is not a valid git repository."
	exit 1
else
	echo "[toolkit]: toolkit is a valid git repository."
fi

# Ensure toolkit remote is correctly set
if [ "$(git -C "$TOOLKIT_REPO_PATH" config --get remote.origin.url)" != "$TOOLKIT_UPSTREAM_URL" ]; then
	echo "[toolkit]: Error: origin is not set to $TOOLKIT_UPSTREAM_URL"
	exit 1
else
	echo "[toolkit]: origin is correctly configured to $TOOLKIT_UPSTREAM_URL"
fi

# =========================================================================== #
# Hook configuration

# Define the targets and hooks
ZPROFILE="$HOME/.zprofile"
PERSONAL_ZPROFILE="$HOME/.zprofile.personal"
ZPROFILE_HOOK="[[ -f $PERSONAL_ZPROFILE ]] && source $PERSONAL_ZPROFILE"

ZSHRC="$HOME/.zshrc"
PERSONAL_ZSHRC="$HOME/.zshrc.personal"
ZSHRC_HOOK="[[ -f $PERSONAL_ZSHRC ]] && source $PERSONAL_ZSHRC"

# Function to safely add a hook to a file
add_hook() {
    local target_file="$1"
    local hook_line="$2"

    # Create the file if it doesn't exist
    if [ ! -f "$target_file" ]; then
        touch "$target_file"
        echo "Created $target_file"
    fi

    # Check if the hook is already there
    if grep -Fxq "$hook_line" "$target_file"; then
        echo "Hook already exists in $target_file"
    else
        # Append the hook to the end of the file
        echo -e "\n$hook_line" >> "$target_file"
        echo "Successfully added hook to $target_file"
    fi
}

# Run the function for both files
add_hook "$ZPROFILE" "$ZPROFILE_HOOK"
add_hook "$ZSHRC" "$ZSHRC_HOOK"

# =========================================================================== #

echo "Temporarily adding tools to path..."
export PATH="$HOME/toolkit/tools:$PATH"

echo "Bootstrap complete. To finalize, use config git status to review and update configuration."
echo "You will likely need to restore configuration if this is a new setup."

# Enable config via legacy...
# TODO: Update how the config system is bootstrapped.
source "$HOME/toolkit/tools/config.sh"

# Always try initializing the toolkit
if ! grep -q "source ~/toolkit/bootstrap.sh" ~/.config/zsh/.zshrc; then
	echo "source ~/toolkit/bootstrap.sh" >> ~/.config/zsh/.zshrc
fi

alias tk=toolkit
