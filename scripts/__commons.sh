#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Utils directory
UTILS_DIR="$(readlink -m "${__DIRNAME}"/utils)"
readonly UTILS_DIR
# Deps directory
DEPS_DIR="$(readlink -m "${__DIRNAME}"/deps)"
readonly DEPS_DIR

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Prevents errors in a pipeline from being masked
set -o pipefail
# Disable wildcard character expansion
set -o noglob

# Logger
# shellcheck source=utils/logger.sh
source "${UTILS_DIR}/logger.sh"
# Default log level
B_LOG --log-level 500

# Check if tool is installed
function assert_tool_silent() {
    command -v "$1" >/dev/null 2>&1 || { FATAL "'$1' is not installed"; exit 1; }
}
function assert_tool() {
    assert_tool_silent "$1"
    INFO "'$1' found at $(command -v "$1")"
}

# Download dependency
function download_dep() {
    if [ -f "$DEPS_DIR/$1" ]; then
        # Already downloaded
        WARN "Dependency '$1' already downloaded"
    else
        # Download dependency
        INFO "Downloading dependency '$1' from $2"
        wget --quiet --show-progress -O "$DEPS_DIR/$1" "$2"
    fi
}

# Assert tool(s)
assert_tool_silent wget
assert_tool_silent shellcheck
assert_tool_silent black
assert_tool_silent gem
