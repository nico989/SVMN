#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=../../scripts/__commons.sh
source "${__DIRNAME}/../scripts/__commons.sh"

# Analyze arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            fvctl_clean && exit 0
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

# FlowVisor slices
INFO "Creating FlowVisor slices"
fvctl_exec add-slice --password=password slice_test tcp:localhost:10001 admin@slice_test

# FlowVisor flowspaces
INFO "Creating FlowVisor flowspaces"
fvctl_exec add-flowspace dpid1 1 1 any slice_test=7
