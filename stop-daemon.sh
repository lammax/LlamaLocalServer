#!/usr/bin/env bash
set -euo pipefail

LABEL="local.aichallenge.llama-server"
TARGET_PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

launchctl bootout "gui/$(id -u)" "${TARGET_PLIST}" >/dev/null 2>&1 || true

echo "Stopped ${LABEL}"
