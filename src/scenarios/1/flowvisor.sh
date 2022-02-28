#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Data port(s)
readonly PORTS=(2 3)
# Current data port
IDX_PORT=0

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

# Calculate next idx port
function next_idx_port() {
    echo $((($1+1)%${#PORTS[@]}))
}

# Start FlowVisor
fvctl_start

# FlowVisor admin slice & flow
INFO "Creating FlowVisor admin slice"
fvctl_exec add-slice --password=password slice_service_migration_admin tcp:localhost:10002 admin@slice_service_migration_admin
INFO "Creating FlowVisor admin flow"
fvctl_exec add-flowspace admin 2 1 any slice_service_migration_admin=7

# FlowVisor data slice
INFO "Creating FlowVisor data slice"
fvctl_exec add-slice --password=password slice_service_migration tcp:localhost:10001 admin@slice_service_migration

# Flowvisor data flow
INFO "Creating FlowVisor data flow"
fvctl_exec add-flowspace dpid1-c0 1 1 in_port=1 slice_service_migration=7
fvctl_exec add-flowspace dpid1-s 1 1 in_port="${PORTS[IDX_PORT]}" slice_service_migration=7

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    # Old port
    OLD_PORT=${PORTS[IDX_PORT]}
    # Update data port
    IDX_PORT="$(next_idx_port "$IDX_PORT")"
    # New port
    NEW_PORT=${PORTS[IDX_PORT]}

    INFO "Migrating from port $OLD_PORT to port $NEW_PORT"

    # FlowVisor
    fvctl_exec remove-flowspace dpid1-s
    sleep 3
    fvctl_stop
    fvctl_start
    fvctl_exec add-flowspace dpid1-s 1 1 in_port="$NEW_PORT" slice_service_migration=7

    INFO "Successfully migrated from port $OLD_PORT to port $NEW_PORT"
done

# Exit
fvctl_clean
INFO "Bye! :)"
