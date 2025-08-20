# === CONFIG SETTINGS ===

REPOS_PATHS_FILE=~/.config/repos/paths

# === Helper Functions ===

__private_repos_get_rel_path () {
	# $1 : relative filename
	abs_path="$(cd "$(dirname -- "$1")" && pwd)/$(basename -- "$1")"
	rel_path="~/${abs_path#$HOME/}"	
	rel_path="${rel_path%/}"
	echo "$rel_path"
}

__private_repos_get_abs_path () {
	abs_path="$(cd "$(dirname -- "$1")" && pwd)/$(basename -- "$1")"
	echo "$abs_path"
}

# === Commands ===

__private_repos_fetch () {
	
	while IFS= read -r; do
		repo="$REPLY"
		repo="${repo/#\~/$HOME}"

		echo "\\033[36m=== $repo ===\\033[0m"

		echo "$(git -C "$repo" fetch --dry-run --verbose)"
	done < "$REPOS_PATHS_FILE"
}

__private_repos_goto () {
	selected="$(__private_repos_list | fzf)"
	selected="${selected/#\~/$HOME}"  # Replace ~ with $HOME
	cd "$selected"
}

__private_repos_add () {
	rel_path="$(__private_repos_get_rel_path "$1")"
	abs_path="$(__private_repos_get_abs_path "$1")"
	if [ -d "$abs_path/.git" ] && [ -d "$abs_path/.git/annex" ]; then
		echo "Skipping add because this appears to be a git-annex repo."
	else
		echo "Adding repo to paths file: $REPOS_PATHS_FILE"
		grep -qx "$rel_path" "$REPOS_PATHS_FILE" && echo "Skipping... Already present?" || echo "$rel_path" >> "$REPOS_PATHS_FILE"	
		# Keep it sorted.
		sort -o "$REPOS_PATHS_FILE" "$REPOS_PATHS_FILE"
	fi
}

# Search for repositories relative to the current directory.
__private_repos_find () {
	echo "finding repos..."

	found=()
	while IFS= read -r -d ''; do
		repo_dir="$(dirname -- "$REPLY")"
		repo_dir="${repo_dir%/.}"
		found+=("$repo_dir")
	done < <(find . -name .git -print0)

	echo ""
	known=()
	unknown=()
	
	for repo in "${found[@]}"; do
		rel_path="$(__private_repos_get_rel_path "$repo")"
		grep -qx "$rel_path" "$REPOS_PATHS_FILE" && known+=("$rel_path") || unknown+=("$rel_path")
	done

	echo "known:"
	for repo in "${known[@]}"; do
		echo "	$repo"	
	done

	echo "unknown:"
	for repo in "${unknown[@]}"; do
		echo "	$repo"
	done


	# TODO: Show repos that are already registered.
}

# List out registered repositories.
__private_repos_list () {
	cat "$REPOS_PATHS_FILE"
}

# Show the status of the registered repositories.
__private_repos_status_long () {

	while IFS= read -r; do
		repo="$REPLY"
		repo="${repo/#\~/$HOME}"  # Replace ~ with $HOME
		echo ""
		echo "\\033[36m=== $repo ===\\033[0m"

		echo "$(git -C "$repo" remote -v)"

		# NOTE: Not clear if the simplify-by-decoration flag here is appropriate. Maybe it will miss things?
		echo "$(git -C "$repo" log --branches --not --remotes --oneline --simplify-by-decoration --decorate --graph)"
		#[ -z "$local_only" ] && echo "$local_only" || true
		
		#echo "branches:"
		#echo "$(git -C "$repo" branch -v)"
		#echo "remote branches:"	
		#echo "$(git -C "$repo" branch -v -r)"
		#echo "remotes:"
		#echo "$(git -C "$repo" remote -v)"
		#echo ""
		echo "status:"
		echo "$(git -C "$repo" status --short --branch)"
		echo ""
		#echo "What just happened?"
		#echo "$(git -C "$repo" log --graph -3 --oneline)"
		#echo ""
		#echo "What am I doing now?"
		#echo "$(git -C "$repo" status --short --branch)"
		#echo ""
		#echo "What is everything I'm working on?"
		#echo "$(git -C "$repo" branch -vv)"
		#echo ""
	done < "$REPOS_PATHS_FILE"	
}

__private_repos_status_of_repo () {

	# NOTE: Types of status lines are:
	# - Local changes that haven't been committed yet.
	# - Local commits that haven't been pushed
	# - Remote commits that haven't been pulled
	# The diff of local/remote are pairings for all remotes that are configured.
	# So, one remote named origin results in 2 local/remote entries.
	# You can think of this as outgoing and incoming for each remote.

	local repo="$1"
	#echo "$repo"
	#echo "args: ${@:1}"
	
	#skip_ok=false
	#if [ "$2" = "--skip-ok" ]; then
	#	skip_ok=true # Should we skip ok repos
	#fi

	local fetch=false
	local dirty_only=false
	
	for arg in "${@:2}"; do
		#echo "Processing: $arg"
		case "$arg" in
			"--dirty")
				dirty_only=true
				;;
			"--fast")
				fetch=false
				;;
			"--fetch")
				fetch=true
				;;
			*)
				echo "Ignoring unknown argument $arg"
				;;
		esac	
	done


	# Process the local changes first. This tells us if we have a dirty or clean repo.
	
	local changes="$(git -C "$repo" status --porcelain)"
	local is_clean=true	
	if [ -n "$changes" ]; then
		is_clean=false
	fi
	
	local remotes=($(git -C "$repo" remote))
	if [ -z "$remotes" ]; then
		is_clean=false # no remotes. mark dirty ? need to show this isn't in a good state.
	fi

	if [ $dirty_only = false ] || [ $is_clean = false ]; then

		local clean_status=$($is_clean && echo "\033[32mCLEAN\033[0m" || echo "\033[31mDIRTY\033[0m")
		echo "$clean_status $repo"

		# Begin processing remote changes. Compare branches with what is on the various remotes.
		
		# NOTE: We'll fetch all changes we can first...
		if [ $fetch = true ]; then
			git -C "$repo" fetch --all
		fi

		if [ -z "$remotes" ]; then
			echo "\033[31mwarn\033[0m No remotes. You should configure an upstream remote."	
		fi

		for remote in "${remotes[@]}"; do
			
			local commits="$(git -C "$repo" log --branches --not --remotes --oneline --simplify-by-decoration --decorate --graph)"

			if [ -n "$commits" ]; then
				echo "- remote: $remote is \033[31mmissing\033[0m:"
				echo "$commits"
			fi	

		done

		local status_sb="$(git -C "$repo" status --short --branch)"

		# Only print if branch is behind remote
		if grep -q "\[behind " <<< "$status_sb"; then
			echo "$status_sb"
		fi

	fi

}

__private_repos_status () {
	local counter=0
	while IFS= read -r; do
		local repo="$REPLY"
		local repo="${repo/#\~/$HOME}"
		__private_repos_status_of_repo "$repo" "${@}"
		counter=$((counter + 1))
	done < "$REPOS_PATHS_FILE"

	echo ""
	echo "Done. Reported on the status of $counter repos."
}

__private_repos_fsck_repo () {
	local repo="$1"
	echo "$repo"
	git -C "$repo" fsck
}

__private_repos_fsck () {
	while IFS= read -r; do
		local repo="$REPLY"
		local repo="${repo/#\~/$HOME}"
		__private_repos_fsck_repo "$repo"
	done < "$REPOS_PATHS_FILE"
}

repos () {
	case "$1" in
		"find")
			__private_repos_find "${@:1}"
			;;
		"list")
			__private_repos_list
			;;
		"add")
			__private_repos_add "${@:2}"
			;;
		"goto")
			__private_repos_goto
			;;
		"fetch")
			__private_repos_fetch
			;;
		"fsck")
			__private_repos_fsck
			;;
		"status")
			__private_repos_status "${@:2}"
			;;
		*)
			echo "Repos tool. Show the status of all the repos on the system."
			echo "Repositories are stored as a list of paths in: ${REPOS_PATHS_FILE/#$HOME/~}"
			echo "Use this tool to keep repositories fully in sync with upstream."
			echo ""
			echo "repos add <path>     - Add a repository to the repos list"
			echo "repos find           - Find repos nearby (searches 3 levels deep in current directory)"
			echo "repos list           - List repos in the repository list"
			echo "repos goto           - Go to one of the repos. Select using fzf."
			echo "repos status         - Show the status of all the registered repositories"
			echo ""
			;;
	esac
}
