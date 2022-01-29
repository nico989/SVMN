#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Watch directory
readonly WATCH_DIR="${__DIRNAME}/../src/"
# Destination directory
readonly DEST_DIR="${__DIRNAME}/../comnetsemu/app/morphing_slices/"

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
assert_tool inotifywait
assert_tool rsync

# Sync watch and destination directories
sync() {
    DEBUG "Syncing '$WATCH_DIR' with destination '$DEST_DIR'"
    rsync --archive --verbose --compress --delete --human-readable "$WATCH_DIR" "$DEST_DIR"
}

# Sync directory
INFO "Syncing directory '$WATCH_DIR'"
sync

# Watcher
INFO "Starting watcher on '$WATCH_DIR' with destination '$DEST_DIR'";
while inotifywait -r -e modify,create,delete,move "$WATCH_DIR"; do
    sync
done
INFO "Watcher stopped";
