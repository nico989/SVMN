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
assert_tool python3
assert_tool pip3
assert_tool pipenv
assert_tool shellcheck
assert_tool inotifywait
assert_tool rsync
assert_tool gem

# Install Python packages
INFO "=== Python packages ==="
INFO "Installing Python packages"
(pipenv install --dev) || { FATAL "Error installing Python packages"; exit 1; }
# Install pre-commit
INFO "Installing 'pre-commit'"
(pipenv run pre-commit install) || { FATAL "Error installing 'pre-commit'"; exit 1; }

# Create and configure comnetsemu
INFO "=== comnetsemu ==="
INFO "Initializing 'comnetsemu'"
(cd "${__DIRNAME}/../comnetsemu" && vagrant up) || { FATAL "Error initializing 'comnetsemu'"; exit 1; }
