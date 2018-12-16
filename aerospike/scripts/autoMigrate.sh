#!/usr/bin/env bash

# Orchestrate the automatic execution of all the aql migration scripts when starting the cluster

# Protect from iterating on empty directories
shopt -s nullglob

function log {
    echo "[$(date)]: $*"
}

function logDebug {
    ((DEBUG_LOG)) && echo "[DEBUG][$(date)]: $*"
}

function waitForClusterConnection() {
    log "Waiting for Aerospike connection..."
#    sleep 10000 # intentionally to debug a little
    retryCount=0
    maxRetry=20
    aql "SHOW NAMESPACES;" -h $AEROSPIKE_HOST &>/dev/null
    while [ $? -ne 0 ] && [ "$retryCount" -ne "$maxRetry" ]; do
        logDebug 'Aerospike not reachable yet. sleep and retry. retryCount =' $retryCount
        sleep 5
        ((retryCount+=1))
        aql "SHOW NAMESPACES;" -h $AEROSPIKE_HOST &>/dev/null
    done

    if [ $? -ne 0 ]; then
      log "Not connected after " $retryCount " retry. Abort the migration."
      exit 1
    fi

    log "Connected to Aerospike cluster"
}

function executeScripts() {
    local filePattern=$1
    # loop over migration scripts
    for aqlFile in $filePattern; do
        . $EXECUTE_AQL_SCRIPT $aqlFile
    done
}

# parse arguments
if [ "$#" -gt 0 ]; then
    log "Override for local usage"
    AQL_FILES_PATH=$1
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    EXECUTE_AQL_SCRIPT=$SCRIPT_DIR'/execute-aql.sh'
else
    AQL_FILES_PATH="/aql/changelog/"
    EXECUTE_AQL_SCRIPT="/usr/local/bin/execute-aql"
fi

log "Start Aerospike migration tool"
waitForClusterConnection
log "Execute all non already executed scripts from $AQL_FILES_PATH"
executeScripts "$AQL_FILES_PATH*.aql"
log "Migration done"
