#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="local.aichallenge.llama-server"
PLIST_NAME="${LABEL}.plist"
SOURCE_PLIST="${SCRIPT_DIR}/${PLIST_NAME}"
TARGET_PLIST="${HOME}/Library/LaunchAgents/${PLIST_NAME}"

mkdir -p "${HOME}/Library/LaunchAgents"
mkdir -p /tmp/LlamaLocalServer

xcodebuild build \
  -quiet \
  -project "${SCRIPT_DIR}/LlamaLocalServer.xcodeproj" \
  -scheme LlamaLocalServer \
  -configuration Release \
  -derivedDataPath "${SCRIPT_DIR}/build"

cp "${SOURCE_PLIST}" "${TARGET_PLIST}"

launchctl bootout "gui/$(id -u)" "${TARGET_PLIST}" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "${TARGET_PLIST}"
launchctl enable "gui/$(id -u)/${LABEL}"
launchctl kickstart -k "gui/$(id -u)/${LABEL}"

echo "Started ${LABEL}"
echo "Logs: /tmp/LlamaLocalServer/llama-server.err.log"
