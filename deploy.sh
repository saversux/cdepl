#!/bin/bash

__DEPLOY_OUT_PATH=""
__DEPLOY_CUR_OUT_PATH=""

##
# Set the output path for configuration files, log files, job scripts etc
# that are created during deployment. Ensure that the location is accessible/
# mounted on all cluster nodes.
#
# $1: Full absolute path to the output location on the cluster
##
cdepl_deploy_out_path()
{
	local path=$1
	
	__DEPLOY_OUT_PATH="$path"
	__DEPLOY_CUR_OUT_PATH="${__DEPLOY_OUT_PATH}/$(date '+%Y-%m-%d_%H-%M-%S-%3N')"

	cdepl_cluster_login_cmd "mkdir -p $__DEPLOY_CUR_OUT_PATH"

	util_log "[deploy] Deployment output path: $__DEPLOY_CUR_OUT_PATH"
}

##
# Endless loop to avoid exiting deployment. Useful for testing/debugging
##
cdepl_deploy_loop_endless()
{
	while true; do
		sleep 100
	done
}
