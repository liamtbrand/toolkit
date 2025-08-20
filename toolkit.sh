#!/bin/sh

# Toolkit for doing work in the terminal.

# I want to use zsh where possible.
# I want to use tmux where possible.
# I also want to use vim or neovim when possible.
# Likewise, tools like fzf are nice to have.
# I want to be able to bootstrap installing these.

TOOLKIT_UPSTREAM_URL="git@github.com:liamtbrand/toolkit.git"

TOOLKIT_REPO_PATH="$HOME/toolkit"
GIT_PATH="/usr/bin/git"

__private_toolkit_git() {
	$GIT_PATH --git-dir="$TOOLKIT_REPO_PATH/.git" --work-tree="$TOOLKIT_REPO_PATH" "${@:1}"
}

TOOLKIT_TOOLS_LIST=()

__private_toolkit_source_module() {
	[ -f "$TOOLKIT_REPO_PATH/tools/$1" ] && source "$TOOLKIT_REPO_PATH/tools/$1" && TOOLKIT_TOOLS_LIST+=("$1") || echo "[toolkit]: Unable to find tool $1"
}

__private_toolkit_modules_load() {
	# Tools
	__private_toolkit_source_module "config.sh"
	__private_toolkit_source_module "homelab.sh"
	__private_toolkit_source_module "notes.sh"
	__private_toolkit_source_module "repos.sh"
	__private_toolkit_source_module "autosync.sh"
}

__private_toolkit_description() {
	echo "Liam's Toolkit."
	echo "Manage configuration using: config"
	echo "Available tools:"
	config modules
	echo "  config"
	echo "  repos"
	echo "  notes"
	echo "  homelab"
	echo "  pass"
	echo "Dependencies:"
	echo "  fzf"
	echo "  zsh"
	echo "  tmux"
	echo "  vim"
	echo "  neovim"
	echo "  bat"
	echo "  delta"
}

__private_toolkit_init() {
	if ! grep -q "source ~/toolkit/toolkit.sh" ~/.config/zsh/.zshrc; then
		echo "source ~/toolkit/toolkit.sh" >> ~/.config/zsh/.zshrc
	fi
}

toolkit () {
	case "$1" in
		"git")
			__private_toolkit_git "${@:2}"
			;;
		"init")
			__private_toolkit_init
			;;
		*)
			__private_toolkit_description
			;;
	esac
}

__private_toolkit_init
__private_toolkit_modules_load

alias tk=toolkit
