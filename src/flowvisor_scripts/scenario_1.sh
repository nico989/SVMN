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

# Define the FlowVisor slices
INFO "Create FlowVisor slice"
fvctl_exec add-slice --password=password slice_test tcp:localhost:10001 admin@slice_test

# Define flowspaces
INFO "Create FlowVisor flows"
fvctl_exec add-flowspace dpid1 1 1 any slice_test=7
