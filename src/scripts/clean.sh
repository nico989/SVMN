#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

INFO "Cleaning 'mininet'"
sudo mn --clean

# Check for running containers and remove
INFO "Cleaning containers"
CONTAINERS="$(docker ps -a -q)"
readonly CONTAINERS
if [ -z "$CONTAINERS" ]; then
    WARN "Empty containers"
else
    INFO "Removing containers"
    # shellcheck disable=SC2086
    sudo docker rm --force ${CONTAINERS}
fi
