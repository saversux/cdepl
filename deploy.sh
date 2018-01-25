#!/bin/bash

__DEPLOY_OUT_PATH=""
__DEPLOY_CUR_OUT_PATH=""

##
# Setup the output path for configuration files, log files, job scripts etc
# that are created during deployment. This location depends on the cluster
# implementation but uses the current user to put it either into his home
# directory or somewhere accessable.
#
# $1: User name of the account to use on the target cluster
# $2: Optional, name of the directory to put all output files to (defaults to 
#     cdepl_out)
##
cdepl_deploy_setup_out_path()
{
	local user=$1
	local subdir_name=$2

	# Use the deploy script name for the out folder
	local filename=$(basename "${BASH_SOURCE[1]}")
	local extension="${filename##*.}"
	filename="${filename%.*}"

	if [ ! "$subdir_name" ]; then
		subdir_name="cdepl_out"
	fi

	__DEPLOY_OUT_PATH="$(cdepl_cluster_get_base_path_deploy_out $user)/$subdir_name"
	__DEPLOY_CUR_OUT_PATH="${__DEPLOY_OUT_PATH}/${filename}_$(date '+%Y-%m-%d_%H-%M-%S-%3N')"

	cdepl_cluster_file_system_cmd "mkdir -p $__DEPLOY_CUR_OUT_PATH"

	util_log "[deploy] Deployment output path: $__DEPLOY_CUR_OUT_PATH"
}

##
# Get the currently set out path for logfiles, configs etc of the deployed
# applications
#
# Return stdout: Current path set
##
cdepl_deploy_get_out_path()
{
	echo "$__DEPLOY_OUT_PATH"
}

##
# Pack the contents of the currently set output folder and move the generated
# archive to a destination (e.g. collecting results)
#
# $1 archive_name Name of the archive (no extension)
# $2 dest_path Destination path to move the file to
##
cdepl_deploy_archive_out_path()
{
	local archive_name=$1
	local dest_path=$2

	local archive="${dest_path}/${archive_name}.tar.gz"

	cdepl_cluster_node_cmd 0 "mkdir -p ${dest_path}"

	util_log "[deploy] Archiving $__DEPLOY_CUR_OUT_PATH to $archive"

	cdepl_cluster_gather_log_files $__DEPLOY_OUT_PATH $__DEPLOY_CUR_OUT_PATH

	cdepl_cluster_node_cmd 0 "cd $__DEPLOY_CUR_OUT_PATH && tar -czvf $archive * > /dev/null 2>&1"
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
