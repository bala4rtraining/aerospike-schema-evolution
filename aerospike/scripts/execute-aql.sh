#!/usr/bin/env bash

unset scripts
declare -A scripts

function log {
    echo "[$(date)]: $*"
}

function logDebug {
    ((DEBUG_LOG)) && echo "[DEBUG][$(date)]: $*"
}

function exitWithError() {
    echo "ERROR :
        $*"
    exit 1
}

#usage checks
if [ -z "$1" ]; then
    echo "usage: ./execute-aql aqlFile.aql"
    exit 1
fi
if [ -z "$AEROSPIKE_HOST" ]; then
    echo "AEROSPIKE_HOST environment variable must be defined"
    exit 1
fi

aqlFile=$1
filename=$(basename "$1")

#load already executed scripts in the `scripts` global variable: dictionary[scriptName->checksum]
function loadExecutedScripts {
    #allow spaces in aql output
    IFS=$'\n'
    # trim to data output only
    local rows=($(aql -c "select * from $AEROSPIKE_SCHEMA_VERSION_NAMESPACE.schema_version;" -h $AEROSPIKE_HOST | tail -n+5 | sed '$d'|sed '$d'|sed '$d'|sed '$d'|sed '$d'|sed '$d'))

    for r in "${rows[@]}"
    do
        local scriptName=$(echo "$r" |cut -d '|' -f 2 | sed s'/^[[:space:]]*//' | sed s'/[[:space:]]*$//')
        local checksum=$(echo "$r" |cut -d '|' -f 3 | sed s'/^[[:space:]]*//' | sed s'/[[:space:]]*$//')
        logDebug "Executed scipt name: $scriptName , checksum: $checksum"
#        scripts+=(["$scriptName"]="$checksum")
        scripts+=([${scriptName}]=${checksum})
    done
    unset IFS
}

# TODO Not works, really not clear why, this should works
exists(){
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: exists {key} in {array}"
    return
  fi
    local arr="$3"
    logDebug "___"
    logDebug "check exists file: $filename"
    logDebug "check exists existing data: ${!arr[@]}"
    logDebug "check exists existing data values: ${arr[@]}"
    logDebug "___"
    eval '[[ ${scripts[$1]+exists} ]]'
}

function checksumEquals {
    local checksum=$(md5sum $aqlFile | cut -d ' ' -f 1)
#    local foundChecksum=${scripts[${filename}]}
    local foundChecksum=${scripts[${filename}]}

    if [[ "$checksum" == "$foundChecksum" ]]; then
        logDebug "checksum equals for $aqlFile, checksum=$checksum"
        return 0
    else
        logDebug "different checksum found for $aqlFile
        checksum=$checksum
   foundChecksum=$foundChecksum"
        return 1
    fi
}

function isExecuted {
    logDebug "check exists for $filename in ${!scripts[@]}"

    if exists $filename in scripts; then
        logDebug "exists"
        if checksumEquals $aqlFile; then
            logDebug "checksum equals"
            return 0
        else
            exitWithError "$aqlFile has already been executed but has a different checksum logged in the schema_version set.
            scripts must not be changed after being executed.
            to resolve this issue you can:
            - revert the modified script to its initial state and create a new script
            OR
            - delete the script entry from the schema_version set
            "
        fi
    else
        logDebug "not exists"
        return 1
    fi
}

function executeAqlScript {
    log "execute: $aqlFile"
    aql -f $aqlFile -h $AEROSPIKE_HOST &>/dev/null
    # if execution failed
    if [ $? -ne 0 ]; then
        exitWithError "fail to apply script $filename
        stop applying database changes"
    fi
    logDebug "execution of $aqlFile succeeded"
}

function logExecutedScript {
    local duration=$1
    local checksum=$(md5sum $aqlFile | cut -d ' ' -f 1)
    local executed_on=$(date +%Y%m%d%H%M%S)
    logDebug "save $aqlFile execution in schema_version table"
    local query="INSERT INTO $AEROSPIKE_SCHEMA_VERSION_NAMESPACE.schema_version (PK, script_name, checksum, executed_by, executed_on, execution_time, status) VALUES ('$filename', '$filename', '$checksum', '$USER', $executed_on, $duration, 'success');"
    aql -c "$query" -h $AEROSPIKE_HOST &>/dev/null
    # if execution failed
    if [ $? -ne 0 ]; then
        exitWithError "fail to save $aqlFile execution to schema_version, stop applying next database changes, ensure manual update as script already applied"
    fi
    logDebug "save $aqlFile execution in schema_version table complete"
}

loadExecutedScripts
if isExecuted; then
    logDebug "skipping $aqlFile already executed"
else
    _start=$(date +"%s")
    executeAqlScript
    _end=$(date +"%s")
    duration=`expr $_end - $_start`
    logExecutedScript $duration
    log "$aqlFile executed with success in $duration seconds"
fi
