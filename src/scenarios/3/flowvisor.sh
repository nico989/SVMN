#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Servers
readonly SLICE_1_SERVERS_IP=("10.0.0.100" "10.0.0.101")
readonly SLICE_1_SERVERS_PORT=(3 4)
readonly SLICE_2_SERVERS_IP=("10.0.0.102" "10.0.0.103")
readonly SLICE_2_SERVERS_PORT=(5 6)
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
INFO "Creating FlowVisor admin slice"
fvctl_exec add-slice --password=password admin tcp:localhost:10003 admin@slice_admin
INFO "Creating FlowVisor admin flow"
fvctl_exec add-flowspace dpid3-admin 3 1 any admin=7

# FlowVisor data slice(s)
INFO "Creating FlowVisor data slice 1"
fvctl_exec add-slice --password=password data_1 tcp:localhost:10001 admin@slice_data_1
INFO "Creating FlowVisor data slice 2"
fvctl_exec add-slice --password=password data_2 tcp:localhost:10002 admin@slice_data_2

# Flowvisor data flow(s)
INFO "Creating FlowVisor data flow for slice 1"
fvctl_exec add-flowspace dpid1-slice1-c 1 1 in_port=1 data_1=7
fvctl_exec add-flowspace dpid1-slice1-s 1 1 in_port="${SLICE_1_SERVERS_PORT[SLICE_1_IDX_SERVER]}" data_1=7
INFO "Creating FlowVisor data flow for slice 2"
fvctl_exec add-flowspace dpid1-slice2-c 1 1 in_port=2 data_2=7
fvctl_exec add-flowspace dpid1-slice2-s 1 1 in_port="${SLICE_2_SERVERS_PORT[SLICE_2_IDX_SERVER]}" data_2=7

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    while : ; do
        read -n1 -r -p "Select slice to migrate [1|2]: " slice
        if [[ ! $slice =~ ^[0-9]+$ ]] ; then
            printf "\n"
            WARN "Slice '$slice' is not a number"
            continue
        fi
        case $slice in
            1)
                SERVERS_IP=( "${SLICE_1_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_1_SERVERS_PORT[@]}" )
                CLIENT_PORT=1
                IDX_SERVER=$SLICE_1_IDX_SERVER
                CONTROLLER_PORT=9876
                FLOW_NAME="dpid1-slice1-s"
                SLICE_NAME="data_1"
                break
            ;;
            2)
                SERVERS_IP=( "${SLICE_2_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_2_SERVERS_PORT[@]}" )
                CLIENT_PORT=2
                IDX_SERVER=$SLICE_2_IDX_SERVER
                CONTROLLER_PORT=9877
                FLOW_NAME="dpid1-slice2-s"
                SLICE_NAME="data_2"
                break
            ;;
            *)
                printf "\n"
                WARN "Slice '$slice' is unknown"
                continue
            ;;
        esac
    done

    # Old ip
    OLD_IP=${SERVERS_IP[IDX_SERVER]}
    # Old port
    OLD_PORT=${SERVERS_PORT[IDX_SERVER]}
    # Update idx server
    IDX_SERVER="$(next_idx_server "$slice" "$IDX_SERVER")"
    # New ip
    NEW_IP=${SERVERS_IP[IDX_SERVER]}
    # New port
    NEW_PORT=${SERVERS_PORT[IDX_SERVER]}

    printf "\n"
    INFO "Migrating from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"

    # Docker manager
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"from\": \"$OLD_IP\", \"to\": \"$NEW_IP\" }" localhost:12345/api/migrate

    # Controller flow
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"dpid\": \"1\", \"in_port\": \"$CLIENT_PORT\", \"out_port\": \"$NEW_PORT\" }" "localhost:$CONTROLLER_PORT/api/migrate"

    # FlowVisor
    fvctl_exec remove-flowspace "$FLOW_NAME"
    fvctl_stop
    fvctl_start
    fvctl_exec add-flowspace "$FLOW_NAME" 1 1 in_port="$NEW_PORT" "$SLICE_NAME=7"

    # Update correct slice_idx_server
    case $slice in
        1) SLICE_1_IDX_SERVER=$IDX_SERVER;;
        2) SLICE_2_IDX_SERVER=$IDX_SERVER;;
        *) FATAL "Slice '$slice' is unknown" && exit 1;;
    esac

    INFO "Successfully migrated slice $slice ($SLICE_NAME) from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
fvctl_clean
INFO "Bye! :)"
