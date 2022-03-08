#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Flowvisor image
readonly FLOWVISOR_IMAGE="flowvisor:latest"
# Docker volume
ARG_VOLUME=""
# Port
PORT=12345
readonly PORT

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Print help message
function print_help() {
cat << EOF
Usage: flowvisor.sh [--help] --volume PATH

Flowvisor Docker script.

Arguments:
  --help         Show this help message and exit
  --volume PATH  Bind mount a volume located at host path
EOF

    exit 1
}

# Analyze arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --volume)
            ARG_VOLUME="$2"
            shift
            shift
        ;;
        --help)
            print_help
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
    docker build --rm -t ${FLOWVISOR_IMAGE} -f "$( readlink -m "${__DIRNAME}/../docker/Dockerfile.flowvisor" )" .
fi

# Start server
INFO "Starting Docker server..."
python3 "${__DIRNAME}/flowvisor.py" --port $PORT > /dev/null 2>&1 &
SERVER_PID="$(jobs -p)"
readonly SERVER_PID
INFO "Docker server started with PID $SERVER_PID"

# Run Flowvisor container
INFO "Run Flowvisor image '${FLOWVISOR_IMAGE}'"
DOCKER_VOLUME="$( readlink -m "${PWD}" )/${ARG_VOLUME}"
INFO "Mounted shared volume ${DOCKER_VOLUME}"
docker run -v "${DOCKER_VOLUME}:/root/flowvisor" -it --rm --network host ${FLOWVISOR_IMAGE} /bin/bash

# Terminate server
kill -9 "$SERVER_PID" > /dev/null 2>&1
