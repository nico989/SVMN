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
# Configuration file
ARG_CONFIG=""

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Print help message
function print_help() {
cat << EOF
Usage: ryu.sh [--help] --controller CONTROLLER --ofport PORT --port PORT [--config PATH]

Ryu script.

Arguments:
  --help                   Show this help message and exit
  --controller CONTROLLER  Ryu Python controller script
  --ofport PORT            OpenFlow port
  --port PORT              Listening port
  --config PATH            Configuration file
EOF

    exit 1
}

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
        --config)
            ARG_CONFIG="$2"
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

# Ryu Manager
INFO "Running ryu: { controller: $ARG_CONTROLLER, ofport: $ARG_OFPORT, port: $ARG_PORT, config: $ARG_CONFIG }"
ryu_cmd=(ryu-manager --observe-links --ofp-tcp-listen-port "${ARG_OFPORT}" --wsapi-port "${ARG_PORT}")
if [ -n "$ARG_CONFIG" ] && [ "$ARG_CONFIG" != " " ]; then
    ryu_cmd+=("--config-file=\"$ARG_CONFIG\"")
fi
ryu_cmd+=("$(dirname "$(python3 -c "import ryu; print(ryu.__file__)")")/app/gui_topology/gui_topology.py") \
ryu_cmd+=("${ARG_CONTROLLER}")
"${ryu_cmd[@]}"
