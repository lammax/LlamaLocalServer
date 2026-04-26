#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/tmp/LlamaLocalServer/llama-server.err.log"

mkdir -p "$(dirname "${LOG_FILE}")"
touch "${LOG_FILE}"

tail -f "${LOG_FILE}"
