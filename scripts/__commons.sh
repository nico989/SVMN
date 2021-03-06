#!/usr/bin/env bash

# Current directory
__THIS_DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __THIS_DIRNAME
# Utils directory
UTILS_DIR="$(readlink -m "${__THIS_DIRNAME}"/utils)"
readonly UTILS_DIR

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
function assert_tool() {
    command -v "$1" >/dev/null 2>&1 || { FATAL "'$1' is not installed"; exit 1; }
    INFO "'$1' found at $(command -v "$1")"
}
