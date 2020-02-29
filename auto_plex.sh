#!/usr/bin/env bash

## Plamen Delchev 28.02.2020

#set -o errexit
set -o pipefail
set -o nounset

usage() {
	cat << EOF

Auto Plexer

Usage: 
	auto_plex <hostname>
	auto_plex -s <hostname>
	auto_plex -c <hostname>

Options:
	-s Show SSH multiplex connection status
	-c Cancel SSH multiplex connection

EOF
}

# Constants
readonly SSH_CONFIG='/Users/plamen.delchev/.ssh/config'
readonly SSH_CONTROL_PATH='/tmp/transfer-%h.local.sock'
readonly SSH_CONTROL_MASTER='auto'
readonly SSH_CONTROL_PERSIST='20m'

while getopts ':s:c:' flag; do
	case "${flag}" in
		s)
			if ! grep -q "${OPTARG}" "${SSH_CONFIG}"; then
				echo "${OPTARG} is not present in ${SSH_CONFIG}" 1>&2
				exit 1
			fi

			ssh -O check "${OPTARG}"
			exit 0
			;;
		c) 
			if ! grep -q "${OPTARG}" "${SSH_CONFIG}"; then
				echo "${OPTARG} is not present in ${SSH_CONFIG}" 1>&2
				exit 1
			fi

			ssh -O exit "${OPTARG}"
			cat "${SSH_CONFIG}.bkp" > "${SSH_CONFIG}" && rm -f "${SSH_CONFIG}.bkp"
			echo "${SSH_CONFIG} reverted from backup"

			exit 0
			;;
		:)
			echo "-${OPTARG} must be followed by an argument we" 1>&2
			exit 1
			;;
		*)
			usage
			exit 1
			;;
	esac
done

if (( $# == 0 )); then
	usage
	exit 1
fi

# Functions
backup_ssh_config() {
	echo -e "Backing up ${SSH_CONFIG} ... "
	if ! cp -f "${SSH_CONFIG}" "${SSH_CONFIG}.bkp"; then
		echo "Unable to backup ${SSH_CONFIG}" 1>&2
		exit 1
	fi
}

generate_multiplex_config() {
	declare -r HOSTNAME="$1"

	readonly MULTIPLEX_CONFIG="Host ${HOSTNAME}
			HostName ${HOSTNAME}
			ControlPath ${SSH_CONTROL_PATH}
			ControlMaster ${SSH_CONTROL_MASTER}
			ControlPersist ${SSH_CONTROL_PERSIST}
	"
}

append_multiplex_config() {
	echo -e "Adding multiplex config into ${SSH_CONFIG} ... "
	if ! echo "${MULTIPLEX_CONFIG}" >> "${SSH_CONFIG}"; then
		echo 'Unable to add the configuration ¯\_(ツ)_/¯' 1>&2
		exit 1
	fi
}

main() {
	backup_ssh_config
	generate_multiplex_config "$1"
	append_multiplex_config

	echo 'Done!'
}

main "$@"
