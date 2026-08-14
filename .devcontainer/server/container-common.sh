#!/bin/bash
export GREAT_MEMORIES_PORT="${DEV_SERVER_PORT:-2283}"
export DEV_PORT="${DEV_PORT:-3000}"

GREAT_MEMORIES_DEVCONTAINER_LOG="$HOME/great-memories-devcontainer.log"

log() {
    # Display command on console, log with timestamp to file
    echo "$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$GREAT_MEMORIES_DEVCONTAINER_LOG"
}

run_cmd() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$GREAT_MEMORIES_DEVCONTAINER_LOG")"

    log "$@"

    # Execute command: display normally on console, log with timestamps to file
    "$@" 2>&1 | tee >(while IFS= read -r line; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line" >>"$GREAT_MEMORIES_DEVCONTAINER_LOG"
    done)

    # Preserve exit status
    return "${PIPESTATUS[0]}"
}

export GREAT_MEMORIES_WORKSPACE="/usr/src/app"

log "Found great-memories workspace in $GREAT_MEMORIES_WORKSPACE"
log ""

