#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Controller
ARG_CONTROLLER=""
# OpenFlow port
ARG_OFPORT=""
# Exposed port
ARG_PORT=""

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Analyze arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --controller)
            ARG_CONTROLLER="$2"
            shift
            shift
        ;;
        --ofport)
            ARG_OFPORT="$2"
            shift
            shift
        ;;
        --port)
            ARG_PORT="$2"
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

# Ryu
INFO "Running ryu: { controller: ${ARG_CONTROLLER}, ofport: ${ARG_OFPORT}, port: ${ARG_PORT} }"
ryu run --observe-links --ofp-tcp-listen-port "${ARG_OFPORT}" --wsapi-port "${ARG_PORT}" \
"$(dirname "$(python3 -c "import ryu; print(ryu.__file__)")")/app/gui_topology/gui_topology.py" \
"${ARG_CONTROLLER}"
