#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

## Plamen Delchev 28.02.2020

## Usage
# Main ~> auto_plex user hostname.com
# Status ~> auto_plex -s
# Cancel ~> auto_plex -c
##

## Main
#	+ Backup original ssh_config 
#	+ Generate multiplex config
#	+ Append multiplex config to ssh_config
##

# Constants
readonly SSH_CONFIG='/Users/plamen.delchev/.ssh/config'
readonly SSH_CONTROL_PATH='/tmp/transfer-%r@%h.local.sock'
readonly SSH_CONTROL_MASTER='auto'
readonly SSH_CONTROL_PERSIST='10m'

# Functions
backup_ssh_config() {
	cp -f "${SSH_CONFIG}" "${SSH_CONFIG}.bkp"
}

generate_multiplex_config() {
	declare -r USERNAME="$1"
	declare -r HOSTNAME="$2"

	readonly MULTIPLEX_CONFIG="Host transfer-${HOSTNAME}
			HostName ${HOSTNAME}
			ControlPath ${SSH_CONTROL_PATH}
			ControlMaster ${SSH_CONTROL_MASTER}
			ControlPersist ${SSH_CONTROL_PERSIST}
	"
}

append_multiplex_config() {
	echo "${MULTIPLEX_CONFIG}" >> "${SSH_CONFIG}"
}

establish_master_connection() {
	ssh "${USERNAME}"@"${HOSTNAME}"
	if (( $? != 0 )); then
		echo "Unable to connected to ${USERNAME}@${HOSTNAME}"
		exit 1
	fi
}

main() {
	backup_ssh_config
	generate_multiplex_config "$@"
	append_multiplex_config
}

main "$@"
