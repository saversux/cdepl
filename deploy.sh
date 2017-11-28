#!/bin/bash

__DEPLOY_OUT_PATH=""
__DEPLOY_CUR_OUT_PATH=""

cdepl_deploy_out_path()
{
	local path=$1
	
	__DEPLOY_OUT_PATH="$path"
	__DEPLOY_CUR_OUT_PATH="${__DEPLOY_OUT_PATH}/$(date '+%Y-%m-%d_%H-%M-%S-%3N')"

	cdepl_cluster_login_cmd "mkdir -p $__DEPLOY_CUR_OUT_PATH"

	util_log "[deploy] Deployment output path: $__DEPLOY_CUR_OUT_PATH"
}

cdepl_deploy_loop_endless()
{
	while true; do
		sleep 100
	done
}
