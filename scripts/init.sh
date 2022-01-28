#!/usr/bin/env bash

# Include Commons file
# shellcheck source=__commons.sh
source "$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )/__commons.sh"

# Assert tool(s)
assert_tool vagrant

# Change current working directory
cd comnetsemu
# Creates and configures comnetsemu
INFO "Initializing 'comnetsemu'"
vagrant up
INFO "Successfully initialized 'comnetsemu'"
