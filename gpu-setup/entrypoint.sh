#!/usr/bin/env bash
# entrypoint.sh - docker entrypoint for claude code GPU image
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# run bootstrap
bash "$SCRIPT_DIR/bootstrap.sh"

# start sshd if available
if command -v sshd > /dev/null 2>&1; then
    echo "starting sshd..."
    mkdir -p /run/sshd
    /usr/sbin/sshd
fi

# keep container alive
echo "container ready. ssh in and run: claude"
exec sleep infinity
