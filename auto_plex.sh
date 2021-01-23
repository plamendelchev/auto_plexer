#!/usr/bin/env bash

## Plamen Delchev 28.02.2020

set -o pipefail
set -o nounset

usage() {
  cat 1>&2 << EOF

Auto Plexer

Usage: 
  auto_plex <hostname>
  auto_plex -s <hostname>
  auto_plex -c <hostname>

Options:
  -s Show SSH multiplex connection status
  -c Cancel SSH multiplex connection
EOF
  exit 1
}

## Exit program if no arguments are provided
(( "$#" == 0 )) && usage

## Helper functions
msg() {
  printf '%s\n' "$@" 2>&1
}
msg_err() {
  printf '%s\n' "$@" 1>&2
  exit 1
}

exists() {
  grep -q "Include ${HOME}/.ssh/$1_config/" "$2"
}

## Source configuration file
readonly LOCAL_CONFIG="${HOME}/.config/auto_plexer"
[[ -e "${LOCAL_CONFIG}" ]] && source "${LOCAL_CONFIG}"

## Main 
while getopts ':s:c:' flag; do
  case "${flag}" in
    s)
      # Check if 'Include ~/.ssh/hostname.com_config' is present in ssh config file
      if ! exists "${OPTARG}" "${SSH_CONFIG}"; then
        msg_err "${OPTARG} is not present in ${SSH_CONFIG}"
      fi

      status="$(ssh -O check "${OPTARG}" 2>&1)"
      if (( "$?" != 0 )); then
        msg "SSH Socket for ${OPTARG} is not active"
      else
        msg "${status}"
      fi

      exit
      ;;
    c) 
      # Check if 'Include ~/.ssh/hostname.com_config' is present in ssh config file
      if ! exists "${OPTARG}" "${SSH_CONFIG}"; then
        msg_err "${OPTARG} is not present in ${SSH_CONFIG}"
      fi

      # Stop SSH session
      ssh -O stop "${OPTARG}" 2> /dev/null

      # Remove Include directive from main ssh config file
      temp="$(grep -Ev "Include .*${OPTARG}_config" "${SSH_CONFIG}")"
      printf '%s' "${temp}" > "${SSH_CONFIG}"

      # Remove multiplex config file
      rm -f "${HOME}/.ssh/${OPTARG}_config"

      msg "SSH Socket for ${OPTARG} deleted!"
      exit
      ;;
    :)
      msg_err "-${OPTARG} must be followed by an argument we"
      ;;
    *)
      usage
      ;;
  esac
done

## Main
msg "Adding multiplex config into ${SSH_CONFIG} ..."

## Populate multiplex config file
readonly HOSTNAME="$1"
readonly MULTIPLEX_SETTINGS="Host ${HOSTNAME}\nControlPath ${SSH_CONTROL_PATH}\nControlMaster ${SSH_CONTROL_MASTER}\nControlPersist ${SSH_CONTROL_PERSIST}"

## Create multiplex config file
readonly MULTIPLEX_FILE="${HOME}/.ssh/${HOSTNAME}_config"
printf '%b\n' "${MULTIPLEX_SETTINGS}" > "${MULTIPLEX_FILE}"

## Include multiplex config in main ssh config file
printf '\nInclude %b\n' "${MULTIPLEX_FILE}" >> ${SSH_CONFIG} 

msg 'Done!'
