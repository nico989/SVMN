#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

INFO "Cleaning 'mininet'"
sudo mn --clean

INFO "Cleaning containers"
# FIXME Check if docker ps is empty. If empty clean otherwise info message e.g. "no container"
# shellcheck disable=SC2046
sudo docker rm --force $(docker ps -a -q)
