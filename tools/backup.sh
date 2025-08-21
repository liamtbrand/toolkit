#!/bin/sh

# This tool is useful for making backups using rsync.
# It's a bit annoying to have to read the manual each time.
# This tool makes it easy to just point and shoot.
# Backup a directory using incremental backup facility of rsync between any two locations.
# Use sane defaults to make sure everything gets copied.
# Review this script and the rsync manual if you're unsure.

# Note: Some backups use old scripts.
# TODO: Build in a feature to identify old scripts and use those where possible?
# Maybe need to abort if an old script is detected?
# Ideally they'll all use the exact same script.

__private_backup_check_dependencies() {
    if ! command -v date &> /dev/null; then
	echo "Error: 'date' is not installed. Aborting script." >&2
	exit 1
    fi

    if ! command -v rsync &> /dev/null; then
	echo "Error: 'rsync' is not installed. Aborting script." >&2
	exit 1
    fi
}

__private_backup_do_incremental_backup() {

    __private_backup_check_dependencies

    # Check arguments to script
    if [ "$#" -ne 2 ]; then
	echo "Error: Exactly two arguments are required."
	echo "Usage: $0 source_path destination_path"
	echo "Note: Source path is the root directory to back up."
	echo "      Destination path will create a directory structure to store the backups."
	exit 1
    fi

    local DATE_TAG=`date "+%Y-%m-%dT%H-%M-%S"`

    local SOURCE_PATH="$1"
    local DESTINATION_PATH="$2"

    if [ ! -d "$DESTINATION_PATH" ]; then
	mkdir -p "$DESTINATION_PATH" && echo "Directory created." || echo "Error: Can't create directory." && exit 1
    fi

    # TODO: Change this since it's now wrong..
    # Switch to this directory...
    cd "$(dirname "$0")"
    # copy the script into the destination so the user can understand how the backup data was created.
    cp "$0" "$DESTINATION_PATH/make-rsync-incremental-backup.sh"

    echo "Generated backups using backup script. See Liam's Toolkit." > "$DESTINATION_PATH/README.md"

    cat > "$DESTINATION_PATH/rsync_ignore" << EOF
.DS_Store
.Spotlight-V100
.DocumentRevisions-V100
.TemporaryItems
.CFUserTextEncoding
EOF

# TODO: Figure out if it is necessary to use "sudo rsync"
# I have a feeling it may be necessary simply in order to copy everything on the machine for machine wide backups.
# Probably need some kind of flag to indicate if the backup is a root level backup or just a local user directory.

    rsync -azP \
	--link-dest="$DESTINATION_PATH/latest" \
	--log-file="$DESTINATION_PATH/backup-$DATE_TAG.log" \
	--exclude-from="$DESTINATION_PATH/rsync_ignore" \
	--rsync-path="sudo rsync" \
	"$SOURCE_PATH" "$DESTINATION_PATH/backup-$DATE_TAG"

    rm -f "$DESTINATION_PATH/latest"
    ln -s "$DESTINATION_PATH/backup-$date" "$DESTINATION_PATH/latest"
}

backup() {
    __private_backup_do_incremental_backup "${@:1}"
}
