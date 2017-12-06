#!/bin/bash

readonly CDEPL_VERSION="0.0.1"
readonly CDEPL_GITREV="$(git log -1 --format=%h --date=short HEAD)"

readonly WORKING_DIR=$(pwd)
readonly CDEPL_SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

# Includes
source ${CDEPL_SCRIPT_DIR}/util.sh
source ${CDEPL_SCRIPT_DIR}/deploy.sh
source ${CDEPL_SCRIPT_DIR}/cluster.sh

##################################
# Exit trap for cleanup on error #
##################################

__cdepl_cleanup_on_exit()
{
    # Check for exit code
    if [ "$?" != "0" ]; then
        if [ "$__CLUSTER_CLEANUP_ON_ERROR" != "1" ]; then
            util_log_warn "[cdepl] Cluster cleanup on error DISABLED"
        else
            util_log "[cdepl] Cluster cleanup on error..."

            _cdepl_cluster_before_cleanup
            cdepl_script_cleanup
            _cdepl_cluster_after_cleanup

            util_log_error "[cdepl] Finished with error"
        fi
    fi
}

###############
# Entry point #
###############

_util_check_bash_version
_util_check_programs

if [ ! "$1" ]; then
    echo "Usage: $0 <deploy_script.cdepl>"
    exit -1
fi

# Check if script available and file
if [ ! -f "$1" ]; then
    util_log_error_and_exit "[cdepl] Script $1 not available or not a file"
fi

# Check extension
filename=$(basename "$1")
if [ "${filename##*.}" != "cdepl" ]; then
    util_log_error_and_exit "[cdepl] Please provide a valid deploy script (.cdepl file)"
fi

###################################
# Start cluster deployment stages #
###################################
# Include deploy script
source $1

# Hook our exit trap
trap __cdepl_cleanup_on_exit EXIT

util_log "========================================="
util_log "cdepl v$CDEPL_VERSION git $CDEPL_GITREV"
util_log "Executing deployment script: $1"
util_log "Working directory: $WORKING_DIRECTORY"
util_log "$(date '+%Y-%m-%d %H:%M:%S:%3N')"
util_log "========================================="

util_log "[cdepl] Cluster node setup..."
cdepl_script_cluster_node_setup
_cdepl_cluster_on_node_setup_finish

util_log "[cdepl] Cluster environment setup..."
cdepl_script_environment_setup
_cdepl_cluster_on_env_setup_finish

util_log "[cdepl] Cluster application deployment..."
_cdepl_cluster_before_deploy
cdepl_script_deploy
_cdepl_cluster_after_deploy

util_log "[cdepl] Cluster cleanup..."
_cdepl_cluster_before_cleanup
cdepl_script_cleanup
_cdepl_cluster_after_cleanup

util_log "[cdepl] Finished"

exit 0