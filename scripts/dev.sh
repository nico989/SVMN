#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Watch directory
readonly WATCH_DIR="${__DIRNAME}/../src/"
# Destination directory
readonly DESTINATION_DIR="${__DIRNAME}/../comnetsemu/app/morphing_slices"

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
assert_tool inotifywait
assert_tool rsync

# Initialize working directory
INFO "Initializing working directory"
rsync -avz "$WATCH_DIR" "$DESTINATION_DIR"

# Watcher
INFO "Starting watcher";
while inotifywait -r -e modify,create,delete,move "$WATCH_DIR"; do
    rsync -avz "$WATCH_DIR" "$DESTINATION_DIR"
done
INFO "Watcher stopped";
