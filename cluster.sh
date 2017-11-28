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

	__cdepl_cluster_check_cluster_api $cluster_name

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
}

__cdepl_cluster_check_cluster_api()
{
	local cluster_type=$1

	__cdepl_cluster_assert_function cdepl_cluster_node_alloc
	__cdepl_cluster_assert_function cdepl_cluster_walltime
	__cdepl_cluster_assert_function cdepl_cluster_node_excl
	__cdepl_cluster_assert_function cdepl_cluster_node_cpus
	__cdepl_cluster_assert_function cdepl_cluster_node_mem
	__cdepl_cluster_assert_function cdepl_cluster_node_network
	__cdepl_cluster_assert_function cdepl_cluster_resolve_dependency
	__cdepl_cluster_assert_function cdepl_cluster_resolve_hostname_to_ip
	__cdepl_cluster_assert_function cdepl_cluster_resolve_node_to_ip
	__cdepl_cluster_assert_function cdepl_cluster_login_cmd
	__cdepl_cluster_assert_function cdepl_cluster_send_file_to_login
	__cdepl_cluster_assert_function cdepl_cluster_node_cmd
	__cdepl_cluster_assert_function cdepl_cluster_get_alloc_node_count
	__cdepl_cluster_assert_function cdepl_cluster_node_resolve_node_to_hostname

	__cdepl_cluster_assert_function _cdepl_cluster_on_init
	__cdepl_cluster_assert_function _cdepl_cluster_on_node_setup_finish
	__cdepl_cluster_assert_function _cdepl_cluster_on_env_setup_finish
	__cdepl_cluster_assert_function _cdepl_cluster_before_deploy
	__cdepl_cluster_assert_function _cdepl_cluster_after_deploy
	__cdepl_cluster_assert_function _cdepl_cluster_before_cleanup
	__cdepl_cluster_assert_function _cdepl_cluster_after_cleanup
}

__cdepl_cluster_assert_function()
{
	local func=$1
	local cluster_type=$2
	
	local type="$(type -t $func)"

	if [ ! "$type" ]; then
		util_log_error_and_exit "[cluster] Missing function $func in cluster type $cluster_type"
	fi

	if [ "$type" != "function" ]; then
		util_log_error_and_exit "[cluster] $func is not a function ($type) in cluster type $cluster_type"
	fi
}