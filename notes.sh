#!/bin/sh

# Manage notes
# Notes are by default at ~/notes.
# To simplify matters, you should symlink from there to your actual notes repository.
# This enables consistent use of the notes tool across systems without modification.

NOTES_REPOSITORY_PATH="$HOME/notes/"

__private_notes_git () {
	/usr/bin/git --git-dir="$NOTES_REPOSITORY_PATH/.git" --work-tree="$NOTES_REPOSITORY_PATH" "${@:1}"
}

notes () {
	case "$1" in
		"git")
			__private_notes_git "${@:2}"
			;;
		*)
			echo "Notes tool. Repo at: $NOTES_REPOSITORY_PATH"
			echo "Manage notes with git."
			echo "Open notes with 'o' or 'ctrl+b + ctrl+o'"
			;;
	esac
}

# This binds the help page to open in neovim by pressing o.
alias o="cd '${NOTES_REPOSITORY_PATH}'; $EDITOR Help.md; cd - >/dev/null"

# Obsidian
alias help="cd '${NOTES_REPOSITORY_PATH}'; $EDITOR Help.md; cd - >/dev/null"

