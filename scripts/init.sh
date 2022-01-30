#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( realpath "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
INFO "=== Checking tools ==="
assert_tool vagrant
assert_tool python

# Download dependencies
INFO "=== Dependencies ==="
download_dep pre-commit.pyz https://github.com/pre-commit/pre-commit/releases/download/v2.17.0/pre-commit-2.17.0.pyz

# Install pre-commit
INFO "Installing 'pre-commit'"
python "$DEPS_DIR/pre-commit.pyz" install

# Create and configure comnetsemu
INFO "=== comnetsemu ==="
INFO "Initializing 'comnetsemu'"
(cd "${__DIRNAME}/../comnetsemu" && vagrant up) || { FATAL "Error initializing 'comnetsemu'"; exit 1; }
INFO "Successfully initialized 'comnetsemu'"
