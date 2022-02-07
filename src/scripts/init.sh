#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# dev_host Docker image
readonly DEV_HOST_IMAGE="dev_host:latest"

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Check dev_host Docker image
if [[ "$(docker images -q ${DEV_HOST_IMAGE} 2> /dev/null)" == "" ]]; then
    WARN "Docker image '${DEV_HOST_IMAGE}' does not exists"
    INFO "Building Docker image '${DEV_HOST_IMAGE}'"
    docker build --rm -t ${DEV_HOST_IMAGE} -f "$( readlink -m "${__DIRNAME}/../docker/Dockerfile.dev_host" )" .
fi

INFO "Installing Python dependencies from 'requirements.txt'"
sudo pip install -r "${__DIRNAME}/../requirements.txt"
