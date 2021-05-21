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

if [ ! -z "$ZONE_ID" || ! -z "$API_TOEN" || ( ! -z "$A_RECORD_ID" && ! -z "$A_RECORD_NAME") ]; then
	echo "Environment variables are missing! Cannot start the container without these variables. "
	echo "Ensure you have the following set correctly: "
	if [ ! -z "$ZONE_ID" ]; then
		echo "	- ZONE_ID/ZONE_ID_FILE"
	fi
	if [ ! -z "$API_TOEN" ]; then
		echo "	- API_TOKEN/API_TOKEN_FILE"
	fi	
	if [ ! -z  "$A_RECORD_ID" && ! -z "$A_RECORD_NAME") ]; then
		echo "	- A_RECORD_ID/A_RECORD_ID_FILE or A_RECORD_NAME/A_RECORD_NAME_FILE"
	fi
	exit 1;
fi

export "CACHED_IP_RECORD"="/tmp/ip"
touch "$CACHED_IP_RECORD"
RECORD=""
# If ID is not set then pull by name
if [ ! -z "$A_RECORD_ID"  &&  -z "$A_RECORD_NAME" ]; then
	RESULT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A$name=$A_RECORD_NAME" \
    			-H "content-type: application/json" \
    			-H "Authorization: Bearer $API_TOKEN"
		)
	A_RECORD_ID=$(echo "$RESULT" | jq -r .result[0].id)
#If Name is not set then pull by ID
elif [  -z "$A_RECORD_ID"  && ! -z "$A_RECORD_NAME" ]; then
	RESULT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
    			-H "content-type: application/json" \
    			-H "Authorization: Bearer $API_TOKEN"
		)
	A_RECORD_NAME=$(echo "$RESULT" | jq -r .result[0].name)
fi
echo  $(echo "$RESULT" | jq -r .result[0].content) > $CACHED_IP_RECORD
	
	
echo "$SCRIPT_SCHEDULE /script.sh  >> /var/log/script.log" | tee /crontab.txt 
/usr/bin/crontab /crontab.txt
ln -sf /dev/stdout /var/log/script.log 
chmod 755 /script.sh /docker-entrypoint.sh 


/usr/sbin/crond -f -l $LOGGING_LEVEL