#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Clean arg flag
ARG_CLEAN=false

# Include commons
# shellcheck source=../../scripts/__commons.sh
source "${__DIRNAME}/../scripts/__commons.sh"

# Analyze arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            ARG_CLEAN=true
            shift
        ;;
        --*)
            WARN "Unknown argument '$1'" && exit 1
        ;;
        *)
            ARGS+=("$1")
            shift
        ;;
    esac
done

# Start FlowVisor
fvctl_start

# Clean FlowVisor
if $ARG_CLEAN; then
    INFO "Cleaning FlowVisor"
    fvctl_clean slice_test
    exit 0
fi

# FlowVisor slices
INFO "Creating FlowVisor slices"
fvctl_exec add-slice --password=password slice_test tcp:localhost:10001 admin@slice_test

# FlowVisor flowspaces
INFO "Creating FlowVisor flowspaces"
fvctl_exec add-flowspace dpid1 1 1 any slice_test=7
