#!/usr/bin/env bash

## Plamen Delchev 28.02.2020

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

# Source configuration file
readonly LOCAL_CONFIG="${HOME}/.config/auto_plexer"
[[ -e "${LOCAL_CONFIG}" ]] && source "${LOCAL_CONFIG}"

# Helper functions
msg() {
  printf '%s\n' "$@" 2>&1
}
msg_err() {
  printf '%s\n' "$@" 1>&2
  exit 1
}

# Main 
while getopts ':s:c:' flag; do
  case "${flag}" in
    s)
      if ! grep -q "${OPTARG}" "${SSH_CONFIG}"; then
        msg_err "${OPTARG} is not present in ${SSH_CONFIG}"
      fi

      ssh -O check "${OPTARG}"
      exit
      ;;
    c) 
      if ! grep -q "${OPTARG}" "${SSH_CONFIG}"; then
        msg_err "${OPTARG} is not present in ${SSH_CONFIG}"
      fi

      ssh -O exit "${OPTARG}"
      cat "${SSH_CONFIG}.bkp" > "${SSH_CONFIG}" && rm -f "${SSH_CONFIG}.bkp"

      msg "${SSH_CONFIG} reverted from backup"

      exit
      ;;
    :)
      msg_err "-${OPTARG} must be followed by an argument we"
      ;;
    *)
      usage 1>&2
      exit 1
      ;;
  esac
done

(( $# == 0 )) && { usage 1>&2; exit 1; }

# Functions
backup_ssh_config() {
  msg "Backing up ${SSH_CONFIG} ... "
  if ! cp -f "${SSH_CONFIG}" "${SSH_CONFIG}.bkp"; then
    msg_err "Unable to backup ${SSH_CONFIG}"
  fi
}

generate_multiplex_config() {
  declare -r HOSTNAME="$@"

  readonly MULTIPLEX_CONFIG="Host "${HOSTNAME}"
  ControlPath ${SSH_CONTROL_PATH}
  ControlMaster ${SSH_CONTROL_MASTER}
  ControlPersist ${SSH_CONTROL_PERSIST}
  "
  echo "${MULTIPLEX_CONFIG}"
}

append_multiplex_config() {
  msg "Adding multiplex config into ${SSH_CONFIG} ..."
  if ! echo -e "\n${MULTIPLEX_CONFIG}" >> "${SSH_CONFIG}"; then
    msg_err 'Unable to add the configuration ¯\_(ツ)_/¯'
  fi
}

main() {
  backup_ssh_config
  generate_multiplex_config "$@"
  append_multiplex_config

  msg 'Done!'
}

main "$@"
