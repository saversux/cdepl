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

readonly UTIL_LOG_LEVEL_DEBUG="4"
readonly UTIL_LOG_LEVEL_INFO="3"
readonly UTIL_LOG_LEVEL_WARN="2"
readonly UTIL_LOG_LEVEL_ERROR="1"
readonly UTIL_LOG_LEVEL_OFF="0"

__UTIL_LOG_LEVEL="4"

##
# Set the log level for the logger calls
#
# $1: Log level (refer to constants)
##
util_log_set_level()
{
	local level=$1

	if [ "$level" -gt "4" ]; then
		level="4"
	elif [ "$level" -lt "0" ]; then
		level="0"
	fi

	__UTIL_LOG_LEVEL="$level"
}

##
# Log an error message and exit cdepl
#
# $1: Message to log
##
util_log_error_and_exit()
{
	local msg=$1

	printf "\e[1;31m${msg}\e[m\nCall trace:\n$(util_print_calltrace)\n"

	exit -1
}

##
# Log an error message
#
# $1: Message to log
##
util_log_error()
{
	local msg=$1

	if [ "$__UTIL_LOG_LEVEL" -ge "1" ]; then
		printf "\e[1;31m${msg}\e[m\n"
	fi
}

##
# Log a warning message
#
# $1: Message to log
##
util_log_warn()
{
	local msg=$1

	if [ "$__UTIL_LOG_LEVEL" -ge "2" ]; then
		printf "\e[1;33m${msg}\e[m\n"
	fi
}

##
# Log a message
#
# $1: Message to log
##
util_log()
{
	local msg=$1

	if [ "$__UTIL_LOG_LEVEL" -ge "3" ]; then
		printf "\e[1;34m${msg}\e[m\n"
	fi
}

##
# Log a debug message
#
# $1: Message to log
##
util_log_debug()
{
	local msg=$1
	local args=${@:2}

	if [ "$__UTIL_LOG_LEVEL" -ge "4" ]; then
		printf "\e[1;32m${msg}\e[m\n" $args
	fi
}

##
# Print the current function call trace to stdout
##
util_print_calltrace()
{
	local i=0
	while true; do
		if [ ! "${FUNCNAME[$i]}" ]; then
			break;
		fi

		echo "${BASH_SOURCE[$i]}:${FUNCNAME[$i]}:${BASH_LINENO[$i]}"
		i=$((i + 1))
	done
}

####################################
# "private" functions for cdepl, not to be called by the user

_util_check_bash_version()
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