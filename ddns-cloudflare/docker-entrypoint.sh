#!/usr/bin/env bash

set -e

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo  "Both $var and $fileVar are set (but are exclusive)"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

	file_env 'ZONE_ID'
	file_env 'API_TOKEN'
	file_env 'A_RECORD_NAME'
	file_env 'A_RECORD_ID'
  
  /usr/sbin/crond -f -l $LOGGING_LEVEL
