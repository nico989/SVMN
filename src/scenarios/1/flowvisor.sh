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
fvctl_exec add-slice --password=password slice_service_migration tcp:localhost:10001 admin@slice_service_migration

# FlowVisor flowspaces
INFO "Creating FlowVisor flowspaces"
fvctl_exec add-flowspace c0-sw0 1 1 any slice_service_migration=7
fvctl_exec add-flowspace s0-sw0 1 1 any slice_service_migration=7
fvctl_exec add-flowspace s1-sw0 1 1 any slice_service_migration=7

fvctl_exec add-flowspace m0-sw1 2 1 any slice_service_migration=7
fvctl_exec add-flowspace s0-sw1-int 2 1 any slice_service_migration=7
fvctl_exec add-flowspace s1-sw1-int 2 1 any slice_service_migration=7
