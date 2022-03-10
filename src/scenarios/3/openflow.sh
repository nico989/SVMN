#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Servers
readonly SERVERS_IP=("10.0.0.100" "10.0.0.101")
readonly SERVERS_PORT=(2 3)
# Current server
IDX_SERVER=0

# Include commons
# shellcheck source=../../scripts/__commons.sh
source "${__DIRNAME}/../../scripts/__commons.sh"

# Assert(s)
if [ ${#SERVERS_IP[@]} -ne ${#SERVERS_PORT[@]} ]; then
    FATAL "Size of 'SERVERS_*' must be equal" && exit 1
fi

# Calculate next idxserver
function next_idx_server() {
    echo $((($1+1)%${#SERVERS_IP[@]}))
}

# OpenFlow admin flow
INFO "Creating OpenFlow admin flow"
ofctl_exec add-flow sw1 actions=normal

# OpenFlow data flow
INFO "Creating OpenFlow data flow"
ofctl_exec add-flow sw0 in_port=1,actions=output:"${SERVERS_PORT[IDX_SERVER]}"
ofctl_exec add-flow sw0 in_port=2,actions=output:1
ofctl_exec add-flow sw0 in_port=3,actions=output:1

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
    docker exec --detach m0 curl -X POST -H \"Content-Type:application/json\" -d "{ \"server\": \"http://$OLD_IP\" }" "$NEW_IP/api/admin/migrate"

    # OpenFlow data flow
    ofctl_exec mod-flows sw0 in_port=1,actions=output:"$NEW_PORT"

    INFO "Successfully migrated from { ip: $OLD_IP, port: $OLD_PORT } to { ip: $NEW_IP, port: $NEW_PORT }"
done

# Exit
ofctl_exec del-flows sw0
ofctl_exec del-flows sw1
INFO "Bye! :)"
