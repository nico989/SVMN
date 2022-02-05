#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Flowvisor image
readonly FLOWVISOR_IMAGE="flowvisor:latest"
# Flowvisor scripts directory
FLOWVISOR_SCRIPTS_DIR="$(readlink -m "${__DIRNAME}"/../flowvisor_scripts)"
readonly FLOWVISOR_SCRIPTS_DIR

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Check Flowvisor Docker image
if [[ "$(docker images -q ${FLOWVISOR_IMAGE} 2> /dev/null)" == "" ]]; then
    WARN "Docker image '${FLOWVISOR_IMAGE}' does not exists"
    INFO "Building Docker image '${FLOWVISOR_IMAGE}'"
    docker build --rm -t ${FLOWVISOR_IMAGE} -f "${__DIRNAME}/Dockerfile.flowvisor" .
fi

# Run Flowvisor container
INFO "Run Flowvisor container"
docker run -v "${FLOWVISOR_SCRIPTS_DIR}:/root/flowvisor_scripts" -it --rm --network host ${FLOWVISOR_IMAGE} /bin/bash
