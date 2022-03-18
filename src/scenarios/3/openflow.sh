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
readonly SLICE_3_SERVERS_IP=("10.0.0.104" "10.0.0.105")
readonly SLICE_3_SERVERS_PORT=(3 4)
readonly SLICE_4_SERVERS_IP=("10.0.0.106" "10.0.0.107")
readonly SLICE_4_SERVERS_PORT=(5 6)
# Current server
SLICE_1_IDX_SERVER=0
SLICE_2_IDX_SERVER=0
SLICE_3_IDX_SERVER=0
SLICE_4_IDX_SERVER=0
# Controller port
readonly CONTROLLER_PORT=9876

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
if [ ${#SLICE_3_SERVERS_IP[@]} -ne ${#SLICE_3_SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SLICE_3_SERVERS_*' must be equal" && exit 1
fi
if [ ${#SLICE_4_SERVERS_IP[@]} -ne ${#SLICE_4_SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SLICE_4_SERVERS_*' must be equal" && exit 1
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
        3)
            echo $((($2+1)%${#SLICE_3_SERVERS_IP[@]}))
        ;;
        4)
            echo $((($2+1)%${#SLICE_4_SERVERS_IP[@]}))
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

# OpenFlow admin slice
INFO "Create admin slice on switch sw2"
sudo ovs-vsctl set port sw2-eth1 qos=@admin -- \
--id=@admin create qos type=linux-htb \
queues:777=@adm -- \
--id=@adm create queue other-config:max-rate=1000000
# OpenFlow admin flow
INFO "Creating OpenFlow admin flow"
ofctl_exec add-flow sw2 actions=set_queue:777,normal

# OpenFlow data slices sw0
INFO "Create slices data_1 and data_2 on switch sw0"
sudo ovs-vsctl set port sw0-eth1 qos=@data -- \
--id=@data create qos type=linux-htb \
queues:123=@data1 \
queues:234=@data2 -- \
--id=@data1 create queue other-config:max-rate=1000000 -- \
--id=@data2 create queue other-config:max-rate=1000000
# OpenFlow data_1 flows
INFO "Creating OpenFlow data_1 flows"
ofctl_exec add-flow sw0 in_port=1,actions=set_queue:123,output:"${SLICE_1_SERVERS_PORT[SLICE_1_IDX_SERVER]}"
ofctl_exec add-flow sw0 in_port=3,actions=set_queue:123,output:1
ofctl_exec add-flow sw0 in_port=4,actions=set_queue:123,output:1
# OpenFlow data_2 flows
INFO "Creating OpenFlow data_2 flows"
ofctl_exec add-flow sw0 in_port=2,actions=set_queue:234,output:"${SLICE_2_SERVERS_PORT[SLICE_2_IDX_SERVER]}"
ofctl_exec add-flow sw0 in_port=5,actions=set_queue:234,output:2
ofctl_exec add-flow sw0 in_port=6,actions=set_queue:234,output:2

# OpenFlow data slices sw1
INFO "Create slices data_3 and data_4 on switch sw1"
sudo ovs-vsctl set port sw1-eth1 qos=@data -- \
--id=@data create qos type=linux-htb \
queues:123=@data3 \
queues:234=@data4 -- \
--id=@data3 create queue other-config:max-rate=1000000 -- \
--id=@data4 create queue other-config:max-rate=1000000
# OpenFlow data_3 flows
INFO "Creating OpenFlow data_1 flows"
ofctl_exec add-flow sw1 in_port=1,actions=set_queue:123,output:"${SLICE_3_SERVERS_PORT[SLICE_3_IDX_SERVER]}"
ofctl_exec add-flow sw1 in_port=3,actions=set_queue:123,output:1
ofctl_exec add-flow sw1 in_port=4,actions=set_queue:123,output:1
# OpenFlow data_4 flows
INFO "Creating OpenFlow data_2 flows"
ofctl_exec add-flow sw1 in_port=2,actions=set_queue:234,output:"${SLICE_4_SERVERS_PORT[SLICE_4_IDX_SERVER]}"
ofctl_exec add-flow sw1 in_port=5,actions=set_queue:234,output:2
ofctl_exec add-flow sw1 in_port=6,actions=set_queue:234,output:2

# Migration loop
while read -n1 -r -p "Press 'Enter' to migrate or 'q' to exit" && [[ $REPLY != q ]]; do
    while : ; do
        read -n1 -r -p "Select slice to migrate [1|2|3|4]: " slice
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
                SLICE_NAME="data_1"
                DATAPATH_ID=1
                break
            ;;
            2)
                SERVERS_IP=( "${SLICE_2_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_2_SERVERS_PORT[@]}" )
                CLIENT_PORT=2
                IDX_SERVER=$SLICE_2_IDX_SERVER
                SLICE_NAME="data_2"
                DATAPATH_ID=1
                break
            ;;
            3)
                SERVERS_IP=( "${SLICE_3_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_3_SERVERS_PORT[@]}" )
                CLIENT_PORT=1
                IDX_SERVER=$SLICE_3_IDX_SERVER
                SLICE_NAME="data_3"
                DATAPATH_ID=2
                break
            ;;
            4)
                SERVERS_IP=( "${SLICE_4_SERVERS_IP[@]}" )
                SERVERS_PORT=( "${SLICE_4_SERVERS_PORT[@]}" )
                CLIENT_PORT=2
                IDX_SERVER=$SLICE_4_IDX_SERVER
                SLICE_NAME="data_4"
                DATAPATH_ID=2
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
    docker exec -d m0 curl -X POST -H \"Content-Type:application/json\" -d "{ \"server\": \"http://$OLD_IP\" }" "$NEW_IP"/api/admin/migrate
    # Controller flow
    curl -X POST -H \"Content-Type:application/json\" -d "{ \"mode\": \"$MIGRATION_MODE\", \"dpid\": \"$DATAPATH_ID\", \"in_port\": \"$CLIENT_PORT\", \"out_port\": \"$NEW_PORT\" }" "localhost:$CONTROLLER_PORT/api/migrate"

    # Update correct slice_idx_server
    case $slice in
        1) SLICE_1_IDX_SERVER=$IDX_SERVER;;
        2) SLICE_2_IDX_SERVER=$IDX_SERVER;;
        3) SLICE_3_IDX_SERVER=$IDX_SERVER;;
        4) SLICE_4_IDX_SERVER=$IDX_SERVER;;
        *) FATAL "Slice '$slice' is unknown" && exit 1;;
    esac

    INFO "Successfully migrated slice $slice ($SLICE_NAME) from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
ofctl_exec del-flows sw0
ofctl_exec del-flows sw1
ofctl_exec del-flows sw2
INFO "Bye! :)"
