#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
assert_tool vagrant

# Change current working directory
cd "${__DIRNAME}/../comnetsemu"
# Creates and configures comnetsemu
INFO "Initializing 'comnetsemu'"
vagrant up
INFO "Successfully initialized 'comnetsemu'"
