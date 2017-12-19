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

	# Use the deploy script name for the out folder
	local filename=$(basename "${BASH_SOURCE[1]}")
	local extension="${filename##*.}"
	filename="${filename%.*}"

	__DEPLOY_OUT_PATH="$path"
	__DEPLOY_CUR_OUT_PATH="${__DEPLOY_OUT_PATH}/${filename}_$(date '+%Y-%m-%d_%H-%M-%S-%3N')"

	cdepl_cluster_login_cmd "mkdir -p $__DEPLOY_CUR_OUT_PATH"

	util_log "[deploy] Deployment output path: $__DEPLOY_CUR_OUT_PATH"
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

	cdepl_cluster_login_cmd "mkdir -p ${dest_path}"

	util_log "[deploy] Archiving $__DEPLOY_CUR_OUT_PATH to $archive"

	cdepl_cluster_login_cmd "cd $__DEPLOY_CUR_OUT_PATH && tar -czvf $archive * > /dev/null 2>&1"
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
