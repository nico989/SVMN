#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Watch directory
readonly WATCH_DIR="${__DIRNAME}/../src/"
# Destination directory
readonly DEST_DIR="${__DIRNAME}/../comnetsemu/app/morphing_slices/"
# Vagrant status
VAGRANT_STATUS=$(cd "${__DIRNAME}"/../comnetsemu && vagrant status --machine-readable | grep ",state," | grep -E -o '([a-z_]*)$')
readonly VAGRANT_STATUS

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
assert_tool inotifywait
assert_tool rsync

# Check Vagrant status
case "${VAGRANT_STATUS}" in
    running)
        INFO "'comnetsemu' is running"
    ;;
    poweroff)
        # Restarting comnetsemu
        INFO "'comnetsemu' is poweroff, restart..."
        INFO "Restarting 'comnetsemu'"
        (cd "${__DIRNAME}/../comnetsemu" && vagrant up) || { FATAL "Error restarting 'comnetsemu'"; exit 1; }
        INFO "Successfully running 'comnetsemu'"
    ;;
    *)
        WARN "Vagrant status '${VAGRANT_STATUS}' not checked"
    ;;
esac

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
