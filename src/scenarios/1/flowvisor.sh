#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Servers
readonly SERVERS_IP=("10.0.0.100" "10.0.0.101")
readonly SERVERS_PORT=(2 3)
readonly SERVER_MAC="00:00:00:00:c0:64"
# Current server
IDX_SERVER=0

# Include commons
# shellcheck source=../../scripts/__commons.sh
source "${__DIRNAME}/../scripts/__commons.sh"

# Assert(s)
if [ ${#SERVERS_IP[@]} -ne ${#SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SERVERS_*' must be equal" && exit 1
fi

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

# Calculate next idx server
function next_idx_server() {
    echo $((($1+1)%${#SERVERS_IP[@]}))
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
fvctl_exec add-flowspace dpid1-s 1 1 in_port="${SERVERS_PORT[IDX_SERVER]}" slice_service_migration=7

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    # Old ip
    OLD_IP=${SERVERS_IP[IDX_SERVER]}
    # Old port
    OLD_PORT=${SERVERS_PORT[IDX_SERVER]}
    # Update idx server
    IDX_SERVER="$(next_idx_server "$IDX_SERVER")"
    # New ip
    NEW_IP=${SERVERS_IP[IDX_SERVER]}
    # New port
    NEW_PORT=${SERVERS_PORT[IDX_SERVER]}

    INFO "Migrating from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"

    # Docker manager
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"from\": \"$OLD_IP\", \"to\": \"$NEW_IP\" }" localhost:12345/api/migrate

    # Controller flow
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"dpid\": \"1\", \"mac\": \"$SERVER_MAC\", \"port\": \"$NEW_PORT\" }" localhost:9876/api/migrate

    # FlowVisor
    fvctl_exec update-flowspace --match=in_port="$NEW_PORT" dpid1-s
    fvctl_stop
    fvctl_start

    INFO "Successfully migrated from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
fvctl_clean
INFO "Bye! :)"
