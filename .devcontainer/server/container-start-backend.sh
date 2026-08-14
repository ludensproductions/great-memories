#!/bin/bash
# shellcheck source=common.sh
# shellcheck disable=SC1091
source /great-memories-devcontainer/container-common.sh

log "Preparing Great Memories Nest API Server"
log ""
export CI=1
run_cmd pnpm --filter great-memories install

log "Starting Nest API Server"
log ""
cd "${GREAT_MEMORIES_WORKSPACE}/server" || (
    log "Great Memories workspace not found"
    exit 1
)

while true; do
    run_cmd pnpm --filter great-memories exec nest start --debug "0.0.0.0:9230" --watch
    log "Nest API Server crashed with exit code $?.  Respawning in 3s ..."
    sleep 3
done
