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


if [ "$ZONE_ID" == EMPTY || "$API_TOEN"==EMPTY || ( "$A_RECORD_ID"== EMPTY && "$A_RECORD_NAME" == EMPTY) ]; then
	echo "Environment variables are missing! Cannot start the container without these variables. "
	echo "Ensure you have the following set correctly: "
	if [ "$ZONE_ID" == EMPTY ]; then
		echo "	- ZONE_ID/ZONE_ID_FILE"
	fi
	if [ "$API_TOEN" == EMPTY ]; then
		echo "	- API_TOKEN/API_TOKEN_FILE"
	fi	
	if [  "$A_RECORD_ID"== EMPTY && "$A_RECORD_NAME" == EMPTY) ]; then
		echo "	- A_RECORD_ID/A_RECORD_ID_FILE or A_RECORD_NAME/A_RECORD_NAME_FILE"
	fi
	exit 1;
fi

touch /tmp/ip
if [ "$A_RECORD_ID" == EMPTY  && "$A_RECORD_NAME" != EMPTY ]; then
	pull down from api
fi
echo "$SCRIPT_SCHEDULE /script.sh  >> /var/log/script.log" | tee /crontab.txt 
/usr/bin/crontab /crontab.txt
ln -sf /dev/stdout /var/log/script.log 
chmod 755 /script.sh /docker-entrypoint.sh 


/usr/sbin/crond -f -l $LOGGING_LEVEL
