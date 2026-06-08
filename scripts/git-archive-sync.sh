#!/usr/bin/env bash

# Hardened bash safety configuration
set -euo pipefail

# Global Configuration Path Defaults (Safely handles spaces without escapes)
ARCHIVE_DIR="${1:-"$HOME/Sync/Archived Git Projects"}"
ENV_FILE="$ARCHIVE_DIR/.env"
LIST_FILE="$ARCHIVE_DIR/repositories.txt"

# ==============================================================================
# 1. CORE UTILITY FUNCTIONS
# ==============================================================================

load_config() {
    if [ -f "$ENV_FILE" ]; then
        # Disable unset variable alerts temporarily to cleanly source external file
        set +u
        source "$ENV_FILE"
        set -u
    else
        echo "Error: Local config file (.env) not found at $ENV_FILE"
        echo "Usage: $0 [/path/to/syncthing/git_archive]"
        exit 1
    fi

    # Resolve the final directory target path from config or fallback
    ARCHIVE_ROOT="${ARCHIVE_ROOT_DIR:-$ARCHIVE_DIR}"
}

prep_environment() {
    # Ensure all target paths and tracker files exist before execution
    touch "$LIST_FILE"
    mkdir -p "$ARCHIVE_ROOT/github"
    mkdir -p "$ARCHIVE_ROOT/local"
}

control_syncthing() {
    local action="$1" # Expects "pause" or "resume"

    if [[ "$action" == "pause" ]]; then
        echo "=== Step 2: Pausing Syncthing Folder: $SYNCTHING_FOLDER_ID ==="
    else
        echo "------------------------------------------------"
        echo "=== Step 4: Resuming Syncthing Folder: $SYNCTHING_FOLDER_ID ==="
    fi

    curl -s -X POST -H "X-API-Key: $SYNCTHING_API_KEY" \
      "http://localhost:8384/rest/system/${action}?folder=$SYNCTHING_FOLDER_ID"

    # Give the system time to settle if freezing file watchers
    if [[ "$action" == "pause" ]]; then
        sleep 3
    fi
}

# ==============================================================================
# 2. REPOSITORY MANAGEMENT FUNCTIONS
# ==============================================================================

discover_github_repos() {
    echo "=== Step 1: Checking GitHub for New Repositories ==="

    if ! command -v gh &> /dev/null || ! gh auth status &> /dev/null; then
        echo "-> WARNING: GitHub CLI (gh) not found or authenticated. Using existing list."
        return 0
    fi

    echo "-> Fetching live repository list from GitHub..."
    local remote_repos
    remote_repos=$(gh repo list --limit 1000 --json sshUrl --jq '.[].sshUrl')

    local new_count=0
    while read -r repo_url; do
        [ -z "$repo_url" ] && continue
        if ! grep -Fxq "$repo_url" "$LIST_FILE"; then
            echo "$repo_url" >> "$LIST_FILE"
            echo "   + Added to master list: $(basename "$repo_url")"
            ((new_count++))
        fi
    done <<< "$remote_repos"

    echo "-> Done checking. Added $new_count new repositories to repositories.txt."
    echo ""
}

process_repo() {
    local repo_url="$1"
    local repo_name
    repo_name=$(basename "$repo_url")

    # Route repository to the correct subdirectory
    local target_dir
    if [[ "$repo_url" == *"github.com"* ]]; then
        target_dir="$ARCHIVE_ROOT/github"
        echo "------------------------------------------------"
        echo "URL: $repo_url -> github/$repo_name"
    else
        target_dir="$ARCHIVE_ROOT/local"
        echo "------------------------------------------------"
        echo "URL: $repo_url -> local/$repo_name"
    fi

    local archive_repo_path="$target_dir/$repo_name"

    # Handle initial setup if the mirror doesn't exist yet
    if [ ! -d "$archive_repo_path" ]; then
        echo "-> Initializing new archive mirror..."
        git clone --mirror "$repo_url" "$archive_repo_path"

        # Universal Safeguard: Apply non-destructive settings to ALL archives
        cd "$archive_repo_path" || exit 1
        git config remote.origin.fetch "refs/*:refs/*"
        git config remote.origin.prune false
    fi

    # Fetch data updates safely (preventing one failure from killing the pipeline)
    cd "$archive_repo_path" || exit 1
    echo "-> Fetching updates..."
    if ! git fetch --all; then
        echo "   ERROR: Fetch failed for $repo_name. Skipping..."
    fi
}


process_all_archives() {
    echo ""
    echo "=== Step 3: Processing Repositories From List ==="

    while IFS= read -r repo_url || [ -n "$repo_url" ]; do
        # Skip blank lines and lines starting with '#' comments
        [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue

        process_repo "$repo_url"
    done < "$LIST_FILE"
}

# ==============================================================================
# 3. MAIN RUNTIME EXECUTION
# ==============================================================================

main() {
    load_config
    prep_environment
    discover_github_repos

    control_syncthing "pause"

    # Trap ensures Syncthing RESUMES even if the user presses Ctrl+C
    # or the loop encounters a fatal shell engine crash.
    trap 'control_syncthing "resume"' EXIT

    process_all_archives

    echo "------------------------------------------------"
    echo "=== Archive Sync Complete! ==="
}

# Launch the script execution
main
