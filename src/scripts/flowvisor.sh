#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Flowvisor image
readonly FLOWVISOR_IMAGE="flowvisor:latest"
# Docker volume
ARG_VOLUME=""

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Analyze arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --volume)
            ARG_VOLUME="$2"
            shift
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

# Check Flowvisor Docker image
if [[ "$(docker images -q ${FLOWVISOR_IMAGE} 2> /dev/null)" == "" ]]; then
    WARN "Docker image '${FLOWVISOR_IMAGE}' does not exists"
    INFO "Building Docker image '${FLOWVISOR_IMAGE}'"
    docker build --rm -t ${FLOWVISOR_IMAGE} -f "${__DIRNAME}/Dockerfile.flowvisor" .
fi

# Run Flowvisor container
INFO "Run Flowvisor image '${FLOWVISOR_IMAGE}'"
DOCKER_VOLUME="$( readlink -m "${PWD}" )/${ARG_VOLUME}"
INFO "Mounted shared volume ${DOCKER_VOLUME}"
docker run -v "${DOCKER_VOLUME}:/root/flowvisor" -it --rm --network host ${FLOWVISOR_IMAGE} /bin/bash
