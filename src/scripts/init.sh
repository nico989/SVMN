#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# dev_host Docker image
readonly DEV_HOST_IMAGE="dev_host:latest"
# Ryu gui topology html directory
RYU_GUI_TOPOLOGY_HTML_DIR="$(dirname "$(python3 -c "import ryu; print(ryu.__file__)")")/app/gui_topology/html"
readonly RYU_GUI_TOPOLOGY_HTML_DIR

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

INFO "Checking Ryu"
if [ ! -d "${RYU_GUI_TOPOLOGY_HTML_DIR}" ]; then
    WARN "Ryu not fixed, fixing..."
    mkdir "${RYU_GUI_TOPOLOGY_HTML_DIR}"
    wget --quiet --show-progress -P "${RYU_GUI_TOPOLOGY_HTML_DIR}" https://raw.githubusercontent.com/faucetsdn/ryu/master/ryu/app/gui_topology/html/index.html
    wget --quiet --show-progress -P "${RYU_GUI_TOPOLOGY_HTML_DIR}" https://raw.githubusercontent.com/faucetsdn/ryu/master/ryu/app/gui_topology/html/router.svg
    wget --quiet --show-progress -P "${RYU_GUI_TOPOLOGY_HTML_DIR}" https://raw.githubusercontent.com/faucetsdn/ryu/master/ryu/app/gui_topology/html/ryu.topology.css
    wget --quiet --show-progress -P "${RYU_GUI_TOPOLOGY_HTML_DIR}" https://raw.githubusercontent.com/faucetsdn/ryu/master/ryu/app/gui_topology/html/ryu.topology.js
    INFO "Ryu fixed"
else
    INFO "Ryu already fixed"
fi
