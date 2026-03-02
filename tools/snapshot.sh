#!/bin/sh

# This tool is useful for making snapshots using rsync.
# It's a bit annoying to have to read the manual each time.
# This tool makes it easy to just point and shoot.
# Can be combined with backup tool.
# Makes an incremental snapshot of a directory.
# Use sane defaults to make sure everything gets copied.
# Review this script and the rsync manual if you're unsure.

__private_backup_check_dependencies() {
    if ! command -v date &> /dev/null; then
	echo "Error: 'date' is not installed. Aborting script." >&2
	return 1
    fi

    if ! command -v rsync &> /dev/null; then
	echo "Error: 'rsync' is not installed. Aborting script." >&2
	return 1
    fi
}

__private_backup_do_incremental_backup() {

    __private_backup_check_dependencies

    local DATE_TAG=`date "+%Y-%m-%dT%H-%M-%S"`

    local SOURCE_PATH="$1"
    local DESTINATION_PATH="$2"

    # NOTE: This has to be run on the target machine?
    # Can I make it so it works across the network?
    # Target should be able to be a remote machine.
    # Pull backups vs push backups.
    if [ ! -d "$DESTINATION_PATH" ]; then
	# Currently this just works for pull backups.
	# Would be nice if it worked for push backups.
	# NOTE: Pull backups seem safer from an access point of view.
	# Maybe its fine to leave this as it is?
	mkdir -p "$DESTINATION_PATH" && echo "Directory created." || echo "Error: Can't create directory." && return 1
    fi

    [ ! -e "$DESTINATION_PATH/README.md" ] && echo "Generated snapshots using backup script. See Liam's Toolkit. https://github.com/liamtbrand/toolkit" > "$DESTINATION_PATH/README.md"

    cat > "$DESTINATION_PATH/rsync_ignore" << EOF
.DS_Store
.Spotlight-V100
.DocumentRevisions-V100
.TemporaryItems
.CFUserTextEncoding
EOF

    rsync -azP \
	--link-dest="$DESTINATION_PATH/latest" \
	--log-file="$DESTINATION_PATH/backup-$DATE_TAG.log" \
	--exclude-from="$DESTINATION_PATH/rsync_ignore" \
	--rsync-path="/usr/bin/rsync" \
	"${@:3}" \
	"$SOURCE_PATH" "$DESTINATION_PATH/backup-$DATE_TAG"

    rm -f "$DESTINATION_PATH/latest"
    ln -s "$DESTINATION_PATH/backup-$date" "$DESTINATION_PATH/latest"
}

backup() {
    # Check arguments to script
    if [ "$#" -lt 2 ]; then
	echo "Backup tool. Make incremental backups."
	echo "Usage: backup source_path destination_path"
	echo "source_path      - Source path is the root node of the directory tree to backup."
	echo "destination_path - Destination path will create a directory structure to store the backups."
	echo "The backup tool makes a pull based incremental backup."
	echo "Push based backups can be configured by having the client reach out to the backup server and request a pull"
	return 1
    fi

    __private_backup_do_incremental_backup "${@:1}"
}
