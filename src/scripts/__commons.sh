#!/usr/bin/env bash

# Current directory
__THIS_DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __THIS_DIRNAME
# Utils directory
UTILS_DIR="$(readlink -m "${__THIS_DIRNAME}"/utils)"
readonly UTILS_DIR
# Time to wait for FlowVisor service
readonly FLOWVISOR_SERVICE_WAIT=3

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

# FlowVisor
# Start FlowVisor
function fvctl_start() {
    INFO "Starting FlowVisor service..."
    /etc/init.d/flowvisor start
    sleep "${FLOWVISOR_SERVICE_WAIT}"
    INFO "FlowVisor service started"
}
# Execute FlowVisor command
function fvctl_exec() {
    fvctl -f /etc/flowvisor/flowvisor.passwd "$@"
}

# Clean FlowVisor slice
function fvctl_clean() {
    fvctl_exec remove-slice "$@"
}
