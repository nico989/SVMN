#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Time to wait for FlowVisor service
readonly FLOWVISOR_SERVICE_WAIT=3

# Include commons
# shellcheck source=../scripts/__commons.sh
source "${__DIRNAME}/../scripts/__commons.sh"

# Execute fvctl command
function fvctl_exec() {
    fvctl -f /etc/flowvisor/flowvisor.passwd "$@"
}

# Start FlowVisor service
INFO "Starting FlowVisor service..."
/etc/init.d/flowvisor start
sleep "${FLOWVISOR_SERVICE_WAIT}"
INFO "FlowVisor service started"

INFO "Cleaning FlowVisor slices"
fvctl_exec remove-slice slice_test
