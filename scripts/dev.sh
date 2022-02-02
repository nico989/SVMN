#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Watch directory
WATCH_DIR="$(readlink -m "${__DIRNAME}"/../src)/"
readonly WATCH_DIR
# Destination directory
DEST_DIR="$(readlink -m "${__DIRNAME}"/../comnetsemu/app/morphing_slices)/"
readonly DEST_DIR
# Vagrant status
VAGRANT_STATUS=$(cd "${__DIRNAME}"/../comnetsemu && vagrant status --machine-readable | grep ",state," | grep -E -o '([a-z_]*)$')
readonly VAGRANT_STATUS

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Check Vagrant status
INFO "=== Checking Vagrant ==="
case "${VAGRANT_STATUS}" in
    running)
        INFO "'comnetsemu' is running"
    ;;
    poweroff)
        # Restarting comnetsemu
        INFO "'comnetsemu' is poweroff, restart..."
        INFO "Restarting 'comnetsemu'"
        (cd "${__DIRNAME}/../comnetsemu" && vagrant up) || { FATAL "Error restarting 'comnetsemu'"; exit 1; }
    ;;
    *)
        ERROR "Vagrant status '${VAGRANT_STATUS}' not checked"
        exit 1
    ;;
esac

# Generate requirements.txt
INFO "Generating 'requirements.txt' from 'pipenv'"
pipenv lock -r > "${__DIRNAME}/../src/requirements.txt"

# Sync watch and destination directories
INFO "=== Sync ==="
function sync() {
    DEBUG "Syncing '$WATCH_DIR' with destination '$DEST_DIR'"
    rsync --archive --verbose --compress --delete --human-readable --quiet "$WATCH_DIR" "$DEST_DIR"
}
# Sync directory
INFO "Syncing directory '$WATCH_DIR'"
sync
# Install Python dependencies
INFO "Installing Python dependencies from generated 'requirements.txt'"
(cd "${__DIRNAME}/../comnetsemu" && vagrant ssh -- -t 'pip install -r comnetsemu/app/morphing_slices/requirements.txt') || { FATAL "Error installing Python dependencies from 'requirements.txt'"; exit 1; }
# Watcher
INFO "Starting watcher on '$WATCH_DIR' with destination '$DEST_DIR'";
while inotifywait --recursive --quiet --event modify,create,delete,move "$WATCH_DIR"; do
    sync
done
INFO "Watcher stopped";
