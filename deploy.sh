#
# Copyright (C) 2018 Heinrich-Heine-Universitaet Duesseldorf, Institute of Computer Science, Department Operating Systems
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#

#!/bin/bash

__DEPLOY_OUT_PATH=""
__DEPLOY_CUR_OUT_PATH=""
__DEPLOY_LOCAL_TMP_PATH=""

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
	__DEPLOY_LOCAL_TMP_PATH="/tmp/cdepl"

	cdepl_cluster_file_system_cmd "mkdir -p $__DEPLOY_CUR_OUT_PATH"
	# create symlink to created folder
	cdepl_cluster_file_system_cmd "ln -sfn $__DEPLOY_CUR_OUT_PATH/ $__DEPLOY_OUT_PATH/${filename}"

	# This path is local for tmp downloads from the lucster
	mkdir -p $__DEPLOY_LOCAL_TMP_PATH

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
# Get the currently set local tmp path used by the application modules to 
# download/upload configuration files to the local node/the cluster
##
cdepl_deploy_get_local_tmp_path()
{
	echo "$__DEPLOY_LOCAL_TMP_PATH"
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
