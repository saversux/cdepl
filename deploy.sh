#!/bin/bash

DEPLOY_OUT_PATH=""
DEPLOY_CUR_OUT_PATH=""

cdepl_deploy_out_path()
{
	local path=$1
	
	DEPLOY_OUT_PATH="$path"
	DEPLOY_CUR_OUT_PATH="${DEPLOY_OUT_PATH}/$(date '+%Y-%m-%d_%H-%M-%S-%3N')"

	cdepl_cluster_login_cmd "mkdir -p $DEPLOY_CUR_OUT_PATH"

	util_log "[deploy] Deployment output path: $DEPLOY_CUR_OUT_PATH"
}

cdepl_deploy_loop_endless()
{
	while true; do
		sleep 100
	done
}
