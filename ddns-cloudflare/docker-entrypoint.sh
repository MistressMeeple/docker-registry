#!/bin/sh

set -e

# logging functions
log() {
	local type="$1"; shift
	# accept argument string or stdin
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	
	printf '%6s [Entrypoint]: %s\n' "[$type]" "$text"
}
note() {
	log Note "$@"
}
msg() {
	log Msg "$@" >&2
}
warn() {
	log Warn "$@" >&2
}
error() {
	log ERR "$@" >&2
}

function file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		error "Both $var and $fileVar are set (but are exclusive)"
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

env_var_check() {
	if [ ! -z "$ZONE_ID" ] || [ ! -z "$API_TOEN" ] ||  ( [ ! -z "$A_RECORD_ID" ] && [ ! -z "$A_RECORD_NAME" ] ); then
		error "Environment variables are missing! Cannot start the container without these variables. " 
		error "Ensure you have the following set correctly: "
		if [ ! -z "$ZONE_ID" ]; then
			error "	- ZONE_ID/ZONE_ID_FILE"
		fi
		if [ ! -z "$API_TOEN" ]; then
			error "	- API_TOKEN/API_TOKEN_FILE"
		fi	
		if [ ! -z  "$A_RECORD_ID" ] && [ ! -z "$A_RECORD_NAME" ]; then
			error "	- A_RECORD_ID/A_RECORD_ID_FILE or A_RECORD_NAME/A_RECORD_NAME_FILE"
		fi
		exit 1;
	else
		msg "Environment variables seem to be setup correctly" 
	fi
}

setup() {
	
	# Turn _FILE env vars to their normal
	file_env 'ZONE_ID'
	file_env 'API_TOKEN'
	file_env 'A_RECORD_NAME'
	file_env 'A_RECORD_ID'
	# Check we have all necessary env vars set
	env_var_check
	# Create the chaced ip record file
	touch "$CACHED_IP_RECORD"
	# load the API scripts
	. /cloudflare-api.sh
	# Run the scripts to update local records from upstream
	update_record_env
	update_cached_ip
	# Create the crontab file, and set it up
	echo "$SCRIPT_SCHEDULE /script.sh  >> /var/log/script.log" | tee /crontab.txt 
	/usr/bin/crontab /crontab.txt
	
	# Link the output from '/script.sh >> /var/log/script.log' to stdout, this allows docker to see the log
	ln -sf /dev/stdout /var/log/script.log 
	msg "Setup complete"
}
setup
# msg "Starting crond"
/usr/sbin/crond -f # -l $LOGGING_LEVEL
