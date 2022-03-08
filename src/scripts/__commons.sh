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
    if [[ "$(/etc/init.d/flowvisor status)" == *"is not runnning"* ]]; then
        INFO "Starting FlowVisor service..."
        /etc/init.d/flowvisor start
        sleep "${FLOWVISOR_SERVICE_WAIT}"
        INFO "FlowVisor service started"
    else
        WARN "FlowVisor is already started"
    fi
}
# Stop FlowVisor
function fvctl_stop() {
    if [[ "$(/etc/init.d/flowvisor status)" == *"is running"* ]]; then
        INFO "Stopping FlowVisor service..."
        /etc/init.d/flowvisor stop
        sleep "${FLOWVISOR_SERVICE_WAIT}"
        INFO "FlowVisor service stopped"
    else
        WARN "FlowVisor is already stopped"
    fi
}
# Execute FlowVisor command
function fvctl_exec() {
    fvctl -f /etc/flowvisor/flowvisor.passwd "$@"
}

# Clean FlowVisor
function fvctl_clean() {
    # Start FlowVisor
    fvctl_start

    INFO "Cleaning FlowVisor"

    # Slices
    slices="$(fvctl_exec list-slices)"
    line_id=$((0))
    while IFS= read -r line; do
        # Ignore first two lines
        if ((line_id<=1)); then ((line_id+=1)) && continue; fi

        slice=$(echo "$line" | awk '{print $1;}')

        INFO "Removing FlowVisor slice '${slice}'"
        fvctl_exec remove-slice "${slice}"

        ((line_id+=1))
    done <<< "$slices"

    INFO "FlowVisor cleaned"
}

# Execute OpenFlow command
function ofctl_exec() {
    sudo ovs-ofctl "$@"
}
