#!/bin/bash

cdepl_cluster_init()
{
	local cluster_name=$1
	local cluster_user=$2

	local available=0

	# Check if scripts for cluster are available
	for f in ${CDEPL_SCRIPT_DIR}/cluster/*; do
		if [ "$f" = "$cluster_name" ]; then
			available=1
		fi
	done

	if [ ! available ]; then
		util_error_and_exit "[cluster] Could not find cluster script for $cluster_name"
	fi

	util_log_debug "[cluster] Cluster selected on init: $cluster_name"

	# Include
	source ${CDEPL_SCRIPT_DIR}/cluster/${cluster_name}

	__cdepl_cluster_check_api

	# Call "constructor"
	_cdepl_cluster_on_init "$cluster_user" "${@:3}"
}

cdepl_cluster_app_load()
{
	local cluster_app=$1

	local available=0

	# Check if scripts for cluster are available
	for f in ${CDEPL_SCRIPT_DIR}/app/*; do
		if [ "$f" = "$cluster_app" ]; then
			available=1
		fi
	done

	if [ ! available ]; then
		util_error_and_exit "[cluster] Could not find application script for $cluster_app"
	fi

	util_log_debug "[cluster] Application loaded: $cluster_app"

	# Include
	source ${CDEPL_SCRIPT_DIR}/app/${cluster_app}

	__cdepl_cluster_check_app_api
}

__cdepl_cluster_check_api()
{
	TODO=""

	# TODO check if all functions with correct names are loaded
}

__cdepl_cluster_check_app_api()
{
	TODO=""

	# TODO check if all functions with correct names are loaded
}