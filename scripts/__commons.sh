#!/usr/bin/env bash

# Utils path
UTILS_PATH="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )/utils"
readonly UTILS_PATH

# Include logger
# shellcheck source=utils/logger.sh
source "${UTILS_PATH}/logger.sh"
# Default log level
B_LOG --log-level 500

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Prevents errors in a pipeline from being masked
set -o pipefail
# Disable wildcard character expansion
set -o noglob

# Check if tool is installed
assert_tool() {
    command -v "$1" >/dev/null 2>&1 || { FATAL "'$1' is not installed"; exit 1; }
}
