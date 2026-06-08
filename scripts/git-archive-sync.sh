#!/usr/bin/env bash

# Hardened bash safety configuration
set -euo pipefail

# Global Configuration Path Defaults (Safely handles spaces without escapes)
ARCHIVE_DIR="${1:-"$HOME/Sync/Archived Git Projects"}"

# Declare globals explicitly so they are safely available to the exit trap
SYNCTHING_FOLDER_ID=""
SYNCTHING_API_KEY="${SYNCTHING_API_KEY:-}"

# ==============================================================================
# 1. CORE UTILITY FUNCTIONS
# ==============================================================================

load_config() {
    # Check if the variable is empty or unset
    if [ -z "${SYNCTHING_API_KEY}" ]; then
        echo "Error: SYNCTHING_API_KEY environment variable is not set."
        echo "Usage: SYNCTHING_API_KEY=\"your_key\" $0 [/path/to/git_archive]"
        exit 1
    fi

    # Resolve the final directory target path from fallback
    ARCHIVE_ROOT="${ARCHIVE_ROOT_DIR:-$ARCHIVE_DIR}"

    # Securely map tracker file to the active root directory
    LIST_FILE="$ARCHIVE_ROOT/repositories.txt"
}

resolve_folder_id() {
    # Dynamically locate the marker file using find instead of ls
    local marker_file
    marker_file=$(find "$ARCHIVE_ROOT/.stfolder" -maxdepth 1 -type f -name "syncthing-folder-*.txt" -print -quit)

    if [ -z "$marker_file" ] || [ ! -f "$marker_file" ]; then
        echo "Error: Could not locate Syncthing marker text file inside $ARCHIVE_ROOT/.stfolder/"
        echo "Please verify this folder is correctly established inside the Syncthing GUI."
        exit 1
    fi

    # Read the folderID property cleanly from the file contents
    SYNCTHING_FOLDER_ID=$(grep "folderID:" "$marker_file" | awk '{print $2}' | tr -d '\r\n[:space:]')

    if [ -z "$SYNCTHING_FOLDER_ID" ]; then
        echo "Error: Found Syncthing marker file, but failed to parse a 'folderID:' value from it."
        exit 1
    fi
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

    # Execute a direct POST against the targeted system runtime control route
    local http_status
    http_status=$(curl -s -k -o /dev/null -w "%{http_code}" -X POST \
      -H "X-API-Key: $SYNCTHING_API_KEY" \
      "https://localhost:8384/rest/system/${action}?folder=${SYNCTHING_FOLDER_ID}")

    # Syncthing returns 200 OK on a successful post invocation change
    if [[ "$http_status" != "200" ]]; then
        echo "Error: Syncthing API rejected folder action '$action' with status code: $http_status"
        exit 1
    fi

    echo "-> Success: Syncthing updated folder state."

    # Give the system time to completely freeze file watchers
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
    resolve_folder_id
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
