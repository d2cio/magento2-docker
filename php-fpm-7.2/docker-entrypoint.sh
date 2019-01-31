#!/bin/bash

set -e

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') $@"
}

SERVICE_NAME="$([[ -n "${SERVICE_NAME}" ]] && echo "${SERVICE_NAME}" || echo "${SERVICE}")"

if [[ "${1}" == "extract" ]]; then

  file="/usr/src/${SERVICE}-${SERVICE_VERSION}.tar.xz"

  log "Extract archive ${file} to /var/www/${SERVICE_NAME}"

  if [[ ! -f "$file" ]]; then
    log "Archive ${file} not found" >&2
    exit 1
  fi

  mkdir -p "/var/www/${SERVICE_NAME}"
  chown www-data:www-data "/var/www/${SERVICE_NAME}"
  tar xJf "${file}" -C "/var/www/${SERVICE_NAME}" --strip-components=1 --keep-newer-files

elif [[ "${@:1:2}" == "backup file" ]]; then

  mkdir -p /var/backups/

  if [[ -n "${3}" && ! -f "/var/backups/${3}" ]]; then
    backup_file="/var/backups/${3}"
  else
    backup_file="/var/backups/${SERVICE}-${SERVICE_VERSION}-$(date '+%Y%m%d%H%M%S.%N')"
  fi

  log "Backup /var/www/${SERVICE_NAME} to ${backup_file}.tar"

  exclude_path=
  for p in $(echo "${EXCLUDE_PATH}" | tr ':' ' '); do
    p="$(echo "${p}" | grep "^/var/www/${SERVICE_NAME}" | sed 's/^\/var\/www\///')"
    if [[ -n "${p}" ]]; then
      exclude_path="${exclude_path} --exclude=\"${p}\""
    fi
  done
  if [[ -n "${exclude_path}" ]]; then
    log "Exclude args: ${exclude_path}"
  fi

  free_size="$(df -B1 --output=avail / | tail -n 1)"
  backup_size="$(tar c ${exclude_path} -C /var/www "${SERVICE_NAME}" | wc -c)"
  if [[ "${backup_size}" -gt "${free_size}" ]]; then
    log "Disk space is too low" >&2
    exit 1
  fi

  tar cf "${backup_file}" ${exclude_path} -C /var/www "${SERVICE_NAME}"
  mv "${backup_file}" "${backup_file}.tar"

elif [[ "${@:1:2}" == "restore file" ]]; then

  if [[ ! -d "/var/backups" ]]; then
    log "Backup path not found" >&2
    exit 1
  fi

  if [[ -n "${3}" && -f "/var/backups/${3}.tar" ]]; then
    backup_file="/var/backups/${3}.tar"
  else
    backup_file=$(find /var/backups -maxdepth 1 -type f -name "${SERVICE}-${SERVICE_VERSION}-*.tar" | sort | tail -n 1)
    if [[ ! -f "${backup_file}" ]]; then
      log "Backup not found" >&2
      exit 1
    fi
  fi

  log "Restore ${backup_file} to /var/www/${SERVICE_NAME}"

  mkdir -p "/var/www/${SERVICE_NAME}"
  chown www-data:www-data "/var/www/${SERVICE_NAME}"
  tar xf "${backup_file}" -C "/var/www/${SERVICE_NAME}" --strip-components=1

elif [[ "${1}" == "remove" ]]; then

  log "Remove all data in /var/www/${SERVICE_NAME}"

  set +e
  rm -rf "/var/www/${SERVICE_NAME}" 2>/dev/null
  set -e

elif [[ "${1#-}" != "$1" ]]; then

  set -- php-fpm "${@}"
  log "Start: ${@}"
  exec "${@}"

elif [[ "${#}" -eq "0" ]]; then

  log "Start: ${@}"
  exec php-fpm

else
  exec "${@}"
fi
