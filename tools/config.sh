#!/bin/bash

# Config tool to manage and update shell configuration
# Used to manage my dotfiles - general config
# These are stored in the config repo.
# Tool also managed modules installed. ?
# Tool also used to manage toolkit itself.
#	-> Moving this responsibility to the toolkit tool.
#
# Try keep as little config as possible in the regular configuration files. (.zshrc)
# This is because various systems have customised configuration.
# It is easier to manage if the configuration is sourced from another file
# than trying to resolve conflicts manually each time.
#
# This tool should really change so its responsibility
# is applying configuration profiles. That is, configure applications
# with user specific settings and customization.
# The tools themselves should come from toolkit.
#
# I'm thinking a workflow like:
# - Update tools using toolkit.
#	-> Includes this config tool
# - Update and apply profile configuration using config tool.
#
# The separation of concerns enables installing tools via the toolkit without
# requiring all of the profile information config would provide.
# The enables using tools and scripts on endpoints without needing
# to use the same dotfiles everywhere. config would not always be necessary.

# The repo names are in order of detection.
# Some systems use dotfiles.git others use config.git.
REPONAMES="dotfiles.git config.git"

CONFIG_REPO="$HOME/dotfiles.git"

__private_config_git () {
	/usr/bin/git --git-dir="$CONFIG_REPO" --work-tree="$HOME" "${@:1}"
}

# To bootstrap config, simply copy this script and execute "config init"
__private_config_init () {
	# Clone git repo into home directory	
	
	# Don't show untracked files
	__private_config_git config --local status.showUntrackedFiles no

}

ZMODDIR="$ZDOTDIR/zshrc.d"
ZMODSLIST=()
__private_source_module () {
	[ -f "$ZMODDIR/$1" ] && source "$ZMODDIR/$1" && ZMODSLIST+=("$1") || echo "[config]: Unable to find module $1"
}

__private_config_modules_load () {

	# Configuration and modifications
	__private_source_module "editor.sh"
	__private_source_module "tmux.sh"
	__private_source_module "gpg.sh"
	__private_source_module "ls.sh"
	__private_source_module "shortcuts.sh"
	__private_source_module "prompt.sh"
	__private_source_module "info.sh"
	__private_source_module "please.sh"
	__private_source_module "haskell.sh"

	# Tools
	__private_source_module "autosync.sh"
	__private_source_module "git-annex.sh"
	__private_source_module "obsidian.sh"
	__private_source_module "tailscale.sh"
	__private_source_module "network.sh"
	__private_source_module "aliases.sh"
	__private_source_module "keyboard.sh"
	__private_source_module "motd.sh"

}

__private_config_modules_list () {
	echo "${ZMODSLIST[@]}"
}

config () {
	case "$1" in
		"git")
			__private_config_git "${@:2}"
			;;
		"init")
			__private_config_init
			;;
		"status")
			# Shortcut to git status
			__private_config_git "${@:1}"
			;;
		"mods"|"modules")
			;;
		*)
			echo "Config tool. Configuration repo: $CONFIG_REPO"
			echo "Usage: config git <command>"
			;;
	esac
}

__private_config_modules_load
