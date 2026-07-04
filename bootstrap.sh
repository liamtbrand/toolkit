#!/usr/bin/env bash
set -euo pipefail

# To bootstrap the toolkit: ./bootstrap.sh
#
# Run this bootstrap script when installing the toolkit or after system reset.
# This will setup the necessary hooks to configure the environment.

# Toolkit for doing work in the terminal.
# I want to be able to bootstrap installing this.

TOOLKIT_UPSTREAM_URL="git@github.com:liamtbrand/toolkit.git"

TOOLKIT_REPO_PATH="$HOME/toolkit"

tk_log() {
	echo "[toolkit] $*"
}

tk_err() {
	echo "[toolkit: ERROR] $*" >&2
	exit 1
}

# If there is no directory for toolkit, clone it.
if [ ! -d "$TOOLKIT_REPO_PATH" ] ; then
	tk_log "toolkit not found at $TOOLKIT_REPO_PATH. cloning from upstream..."
	git clone "$TOOLKIT_UPSTREAM_URL" "$TOOLKIT_REPO_PATH" || tk_err "Failed to clone from upstream."
else
	tk_log "toolkit found at $TOOLKIT_REPO_PATH"
fi

# Ensure toolkit is in fact toolkit
if ! git -C "$TOOLKIT_REPO_PATH" rev-parse --git-dir >/dev/null 2>&1 ; then
	tk_err "$TOOLKIT_REPO_PATH is not a valid git repository."
else
	tk_log "toolkit is a valid git repository."
fi

# Ensure toolkit remote is correctly set
if [ "$(git -C "$TOOLKIT_REPO_PATH" config --get remote.origin.url)" != "$TOOLKIT_UPSTREAM_URL" ]; then
	tk_err "origin is not set to $TOOLKIT_UPSTREAM_URL"
else
	tk_log "origin is correctly configured to $TOOLKIT_UPSTREAM_URL"
fi

# =========================================================================== #
# Install dependencies

DEPENDENCIES_FILE="dependencies.txt"

# Function to install dependencies
install_dependencies() {
    if [ ! -f "$DEPENDENCIES_FILE" ]; then
        tk_log "No $DEPENDENCIES_FILE found. Skipping dependency installation."
        return
    fi

    OS_TYPE=$(uname -s)

    if [ "$OS_TYPE" = "Darwin" ]; then
        tk_log "Detected macOS (Darwin). Installing dependencies via Homebrew..."

        if ! command -v brew &> /dev/null; then
            tk_err "Homebrew is not installed."
        fi

        # Safely read file line by line under strict mode
        while IFS= read -r package || [ -n "$package" ]; do
            [[ -z "$package" || "$package" =~ ^# ]] && continue

            # Skip if the command exists anywhere in your system PATH
            if command -v "$package" &> /dev/null; then
                tk_log "$package already exists on this system. Skipping..."
                continue
            fi

            tk_log "Installing $package via brew..."
            brew install "$package"
        done < "$DEPENDENCIES_FILE"

    elif [ "$OS_TYPE" = "Linux" ] && [ -f /etc/debian_version ]; then
        tk_log "Detected Ubuntu/Debian Linux. Installing dependencies via apt..."

        tk_log "Updating apt package list..."
        sudo apt update

        while IFS= read -r package || [ -n "$package" ]; do
            [[ -z "$package" || "$package" =~ ^# ]] && continue
            tk_log "Installing $package via apt..."
            sudo apt install -y "$package"
        done < "$DEPENDENCIES_FILE"
    else
	tk_err "Unsupported operating system. Skipping installations. Stopping bootstrap. FAILED"
    fi
}

# Run the dependency installer
install_dependencies

# =========================================================================== #
# Hook configuration

# Define the targets and hooks
ZPROFILE="$HOME/.zprofile"
PERSONAL_ZPROFILE="$HOME/.zprofile.personal"
ZPROFILE_HOOK="[[ -f $PERSONAL_ZPROFILE ]] && source $PERSONAL_ZPROFILE"

ZSHRC="$HOME/.zshrc"
XDG_ZSHRC="$HOME/.config/zsh/.zshrc"
PERSONAL_ZSHRC="$HOME/.config/zsh/.zshrc.personal"
ZSHRC_HOOK="[[ -f $PERSONAL_ZSHRC ]] && source $PERSONAL_ZSHRC"

# Function to safely add a hook to a file
add_hook() {
    local target_file="$1"
    local hook_line="$2"

    # Create the file if it doesn't exist
    if [ ! -f "$target_file" ]; then
        touch "$target_file"
	tk_log "Created $target_file"
    fi

    # Check if the hook is already there
    if grep -Fxq "$hook_line" "$target_file"; then
        tk_log "Hook already exists in $target_file"
    else
        # Append the hook to the end of the file
        echo -e "\n$hook_line" >> "$target_file"
        tk_log "Successfully added hook to $target_file"
    fi
}

# Run the function for both files
add_hook "$ZPROFILE" "$ZPROFILE_HOOK"
add_hook "$ZSHRC" "$ZSHRC_HOOK"
add_hook "$XDG_ZSHRC" "$ZSHRC_HOOK"

# =========================================================================== #

tk_log "Temporarily adding tools to path..."
export PATH="$HOME/toolkit/tools:$PATH"

tk_log "Bootstrap complete. To finalize, use config git status to review and update configuration."
tk_log "You will likely need to restore configuration if this is a new setup."

# Temporarily alias toolkit (permanent from config settings)
alias tk=toolkit
