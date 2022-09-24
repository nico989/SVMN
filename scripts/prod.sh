#!/usr/bin/env bash

# Current directory
__DIRNAME="$(dirname "$( readlink -m "${BASH_SOURCE[0]}" )" )"
readonly __DIRNAME
# Source directory
SRC_DIR="$(readlink -m "${__DIRNAME}"/../src)"
readonly SRC_DIR
# Tmp directory
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'morphing_slices')"
readonly TMP_DIR
# Tarball|Gzip name
readonly TAR_GZ_NAME="morphing_slices.tar.gz"

# Include commons
# shellcheck source=__commons.sh
source "${__DIRNAME}/__commons.sh"

# Assert tool(s)
INFO "=== Checking tools ==="
assert_tool pipenv
assert_tool tar

# Files
INFO "=== Sources ==="
# Copy sources to build directory
INFO "Copying sources from $SRC_DIR to $TMP_DIR"
cp -a "$SRC_DIR/." "$TMP_DIR/"
# Generate requirements.txt
INFO "Generating 'requirements.txt' from 'pipenv'"
pipenv requirements > "$TMP_DIR/requirements.txt"
# README & assets
INFO "Copying README and assets"
cp README.md "$TMP_DIR/"
cp -R assets "$TMP_DIR/"

# tar|gz file
INFO "=== ${TAR_GZ_NAME} ==="
# Remove old tar|gz file
if [ -f "${TAR_GZ_NAME}" ]; then
    INFO "Removing old '${TAR_GZ_NAME}'"
    rm --force "${TAR_GZ_NAME}"
fi
# Generate final tar|gz file
INFO "Generating '${TAR_GZ_NAME}'"
find "${TMP_DIR}" -printf "%P\n" | tar -czf "${TAR_GZ_NAME}" --no-recursion -C "${TMP_DIR}" -T -
