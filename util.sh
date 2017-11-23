#!/bin/bash

######################################################
# Print a error message and exit
# Globals:
# Arguments:
#   msg: The message to print
######################################################
util_log_error_and_exit()
{
	local msg=$1
	local args=${@:2}

	printf "\e[1;31m${msg}\e[m\n" $args
	exit -1
}

######################################################
# Print a warning message
# Globals:
# Arguments:
#   msg: The message to print
######################################################
util_log_warn()
{
	local msg=$1
	local args=${@:2}

	printf "\e[1;33m${msg}\e[m\n" $args
}

######################################################
# Print a error message
# Globals:
# Arguments:
#   msg: The message to print
######################################################
util_log_error()
{
	local msg=$1
	local args=${@:2}

	printf "\e[1;31m${msg}\e[m\n" $args
}

######################################################
# Print a normal log message
# Globals:
# Arguments:
#   msg: The message to print
######################################################
util_log()
{
	local msg=$1
	local args=${@:2}

	printf "\e[1;34m${msg}\e[m\n" $args
}

######################################################
# Print a debug log message
# Globals:
# Arguments:
#   msg: The message to print
######################################################
util_log_debug()
{
	local msg=$1
	local args=${@:2}

	printf "\e[1;32m${msg}\e[m\n" $args
}

######################################################
# Check if the current shell is bash and the minimum 
# version requirements
# Globals:
# Arguments:
######################################################
util_check_bash_version()
{
	if [ "$(echo $SHELL | grep "bash")" = "" ] ; then
		util_error_and_exit "Current shell not supported by deploy script, bash only"
	fi

	# Some features like "declare -A" require version 4
	if [ $(echo ${BASH_VERSION%%[^0-9]*}) -lt 4 ]; then
	    read versionCheck <<< $(echo ${BASH_VERSION%%[^0-9]* } | awk -F '.' '{split($3, a, "("); print a[1]; print ($1 >= 3 && $2 > 2) ? "YES" : ($2 == 2 && a[1] >= 57) ? "YES" : "NO" }')
        if [ "$versionCheck" == "NO" ]; then
			util_error_and_exit "Bash version >= 3.2.57 required (Recommended is version 4)"
		fi
	fi
}

######################################################
# Check for a few basic tools we need to run the 
# scripts
# Globals:
# Arguments:
######################################################
util_check_programs()
{
	local nodes=$1

	# TODO we need a version of this (in cluster.sh?) to check for programms installed
	# on remote nodes (e.g. realpath)

	if [ ! hash cat 2>/dev/null ]; then
		util_error_and_exit "Please install coreutils. Used for cat, cut, mkdir, readlink, rm and sleep."
	fi

	if [ ! hash grep 2>/dev/null ]; then
		util_error_and_exit "Please install grep."
	fi

	if [ ! hash sed 2>/dev/null ]; then
		util_error_and_exit "Please install sed."
	fi

	if [ ! hash hostname 2>/dev/null ]; then
		util_error_and_exit "Please install hostname."
	fi

	if [ ! hash pkill 2>/dev/null ]; then
		util_error_and_exit "Please install procps. Used for pkill."
	fi

	if [ ! hash host 2>/dev/null ]; then
		util_error_and_exit "Please install bind9-host. Used for host."
	fi

	if [ ! hash dig 2>/dev/null ]; then
		util_error_and_exit "Please install dnsutils. Used for dig."
	fi

	if [ ! hash ssh 2>/dev/null ]; then
		util_error_and_exit "Please install openssh-client. Used for scp and ssh."
	fi
}