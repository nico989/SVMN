#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
assert_tool vagrant

# Creates and configures comnetsemu
INFO "Initializing 'comnetsemu'"
(cd "${__DIRNAME}/../comnetsemu" && vagrant up) || { FATAL "Error initializing 'comnetsemu'"; exit 1; }
INFO "Successfully initialized 'comnetsemu'"
