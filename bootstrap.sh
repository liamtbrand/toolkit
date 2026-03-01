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
fi

# Ensure toolkit is in fact toolkit
if ! git -C "$TOOLKIT_REPO_PATH" rev-parse --git-dir >/dev/null 2>&1 ; then
	echo "[toolkit]: Error: $TOOLKIT_REPO_PATH is not a valid git repository."
	exit 1
fi

# Ensure toolkit remote is correctly set
if [ "$(git -C "$TOOLKIT_REPO_PATH" config --get remote.origin.url)" != "$TOOLKIT_UPSTREAM_URL" ]; then
	echo "[toolkit]: Error: origin is not set to $TOOLKIT_UPSTREAM_URL"
	exit 1
fi

# Add tools to the path
export PATH="$HOME/toolkit/tools:$PATH"

# Enable config via legacy...
# TODO: Update how the config system is bootstrapped.
source "$HOME/toolkit/tools/config.sh"

# Always try initializing the toolkit
if ! grep -q "source ~/toolkit/bootstrap.sh" ~/.config/zsh/.zshrc; then
	echo "source ~/toolkit/bootstrap.sh" >> ~/.config/zsh/.zshrc
fi

alias tk=toolkit
