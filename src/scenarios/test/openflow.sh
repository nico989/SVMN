#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Migration mode
MIGRATION_MODE=
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
source "${__DIRNAME}/../../scripts/__commons.sh"

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

# Migration mode
while : ; do
    read -n1 -r -p "Select migration mode [1->UPDATE|2->DELETE]: " migration_mode
    printf "\n"
    if [[ ! $migration_mode =~ ^[0-9]+$ ]] ; then
        WARN "Mode '$migration_mode' is not a number"
        continue
    fi
    case $migration_mode in
        1 | 2)
            MIGRATION_MODE=$migration_mode
            break
        ;;
        *)
            WARN "Mode '$migration_mode' is unknown"
            continue
        ;;
    esac
done

# OpenFlow admin flow
INFO "Creating OpenFlow admin flow"
ofctl_exec add-flow sw1 actions=normal

# OpenFlow data flow
INFO "Creating OpenFlow data flow"
ofctl_exec add-flow sw0 in_port=1,actions=output:"${SLICE_1_SERVERS_PORT[SLICE_1_IDX_SERVER]}"
ofctl_exec add-flow sw0 in_port=3,actions=output:1
ofctl_exec add-flow sw0 in_port=4,actions=output:1

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    while : ; do
        read -n1 -r -p "Select slice to migrate [1|2]: " slice
        printf "\n"
        if [[ ! $slice =~ ^[0-9]+$ ]] ; then
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
                SLICE_NAME="data_1"
                break
            ;;
            2)
                SERVERS_IP=( "${SLICE_2_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_2_SERVERS_PORT[@]}" )
                CLIENT_PORT=2
                IDX_SERVER=$SLICE_2_IDX_SERVER
                CONTROLLER_PORT=9877
                SLICE_NAME="data_2"
                break
            ;;
            *)
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

    INFO "Migrating from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"

    # Docker manager
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"from\": \"$OLD_IP\", \"to\": \"$NEW_IP\" }" localhost:12345/api/migrate

    # Controller flow
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"mode\": \"$MIGRATION_MODE\", \"dpid\": \"1\", \"in_port\": \"$CLIENT_PORT\", \"out_port\": \"$NEW_PORT\" }" "localhost:$CONTROLLER_PORT/api/migrate"

    # Update correct slice_idx_server
    case $slice in
        1) SLICE_1_IDX_SERVER=$IDX_SERVER;;
        2) SLICE_2_IDX_SERVER=$IDX_SERVER;;
        *) FATAL "Slice '$slice' is unknown" && exit 1;;
    esac

    INFO "Successfully migrated slice $slice ($SLICE_NAME) from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
ofctl_exec del-flows sw0
ofctl_exec del-flows sw1
ofctl_exec del-flows sw2
INFO "Bye! :)"
