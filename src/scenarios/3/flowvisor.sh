#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Servers
readonly SLICE_1_SERVERS_IP=("10.0.0.100" "10.0.0.101")
readonly SLICE_1_SERVERS_PORT=(3 4)
readonly SLICE_2_SERVERS_IP=("10.0.0.102" "10.0.0.103")
readonly SLICE_2_SERVERS_PORT=(5 6)
readonly SERVER_MAC="00:00:00:00:c0:64"
# Current server
SLICE_1_IDX_SERVER=0
SLICE_2_IDX_SERVER=0

# Include commons
# shellcheck source=../../scripts/__commons.sh
source "${__DIRNAME}/../scripts/__commons.sh"

# Assert(s)
if [ ${#SLICE_1_SERVERS_IP[@]} -ne ${#SLICE_1_SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SLICE_1_SERVERS_*' must be equal" && exit 1
fi
if [ ${#SLICE_2_SERVERS_IP[@]} -ne ${#SLICE_2_SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SLICE_2_SERVERS_*' must be equal" && exit 1
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
    case $1 in
        1)
            echo $((($2+1)%${#SLICE_1_SERVERS_IP[@]}))
        ;;
        2)
            echo $((($2+1)%${#SLICE_2_SERVERS_IP[@]}))
        ;;
        *) FATAL "Slice index '$1' is unknown" && exit 1;;
    esac
}

# Start FlowVisor
fvctl_start

# FlowVisor admin slice & flow
#INFO "Creating FlowVisor admin slice"
#fvctl_exec add-slice --password=password slice_service_migration_admin tcp:localhost:10002 admin@slice_service_migration_admin
#INFO "Creating FlowVisor admin flow"
#fvctl_exec add-flowspace admin 2 1 any slice_service_migration_admin=7

# FlowVisor data slice(s)
INFO "Creating FlowVisor data slice 1"
fvctl_exec add-slice --password=password slice_data_1 tcp:localhost:10001 admin@slice_data_1
INFO "Creating FlowVisor data slice 2"
fvctl_exec add-slice --password=password slice_data_2 tcp:localhost:10002 admin@slice_data_2

# Flowvisor data flow(s)
INFO "Creating FlowVisor data flow for slice 1"
fvctl_exec add-flowspace dpid1-slice1-c 1 1 in_port=1 slice_data_1=7
fvctl_exec add-flowspace dpid1-slice1-s 1 1 in_port="${SLICE_1_SERVERS_PORT[SLICE_1_IDX_SERVER]}" slice_data_1=7
INFO "Creating FlowVisor data flow for slice 2"
fvctl_exec add-flowspace dpid1-slice2-c 1 1 in_port=2 slice_data_2=7
fvctl_exec add-flowspace dpid1-slice2-s 1 1 in_port="${SLICE_2_SERVERS_PORT[SLICE_2_IDX_SERVER]}" slice_data_2=7

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    read -n1 -r -p "Select slice to migrate [1|2]: " slice
    if [[ ! $slice =~ ^[0-9]+$ ]] ; then
        WARN "Slice '$slice' is not a number"  && continue
    fi
    case $slice in
        1)
            SERVERS_IP=SLICE_1_SERVERS_IP
            SERVERS_PORT=SLICE_1_SERVERS_PORT
            IDX_SERVER=SLICE_1_IDX_SERVER
            CONTROLLER_PORT="9876"
            FLOW_NAME="dpid1-slice1-s"
            SLICE_NAME="slice_data_1"
        ;;
        2)
            SERVERS_IP=SLICE_2_SERVERS_IP
            SERVERS_PORT=SLICE_2_SERVERS_PORT
            IDX_SERVER=SLICE_2_IDX_SERVER
            CONTROLLER_PORT="9877"
            FLOW_NAME="dpid1-slice2-s"
            SLICE_NAME="slice_data_2"
        ;;
        *) WARN "Slice '$slice' is unknown" && continue;;
    esac

    # Old ip
    OLD_IP=${SERVERS_IP[IDX_SERVER]}
    # Old port
    OLD_PORT=${SERVERS_PORT[IDX_SERVER]}
    # Update idx server
    # TODO: CHECK
    IDX_SERVER="$(next_idx_server "$slice" "$IDX_SERVER")"
    # New ip
    NEW_IP=${SERVERS_IP[IDX_SERVER]}
    # New port
    NEW_PORT=${SERVERS_PORT[IDX_SERVER]}

    INFO "Migrating from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"

    # Docker manager
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"from\": \"$OLD_IP\", \"to\": \"$NEW_IP\" }" localhost:12345/api/migrate

    # Controller flow
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"dpid\": \"1\", \"mac\": \"$SERVER_MAC\", \"port\": \"$NEW_PORT\" }" "localhost:$CONTROLLER_PORT/api/migrate"

    # FlowVisor
    fvctl_exec remove-flowspace "$FLOW_NAME"
    fvctl_stop
    fvctl_start
    fvctl_exec add-flowspace "$FLOW_NAME" 1 1 in_port="$NEW_PORT" "$SLICE_NAME=7"

    INFO "Successfully migrated slice $slice ($SLICE_NAME) from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
fvctl_clean
INFO "Bye! :)"
