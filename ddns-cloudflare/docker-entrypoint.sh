#!/bin/sh

set -e

# logging functions
log() {
	local type="$1"; shift
	# accept argument string or stdin
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	
	printf '[%5s][Entrypoint]: %s\n' "$type" "$text"
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
	log ERROR "$@" >&2
}


env_var_check() {
	if [ ! -z "$ZONE_ID" ] || [ ! -z "$API_TOEN" ] ||  ( [ ! -z "$A_RECORD_ID" ] && [ ! -z "$A_RECORD_NAME" ] ); then
		error "Environment variables are missing! Cannot start the container without these variables. " 
		error "Ensure you have the following set correctly: "
		if [ ! -z "$ZONE_ID" ]; then
			error "	- ZONE_ID"
		fi
		if [ ! -z "$API_TOEN" ]; then
			error "	- API_TOKEN"
		fi	
		if [ ! -z  "$A_RECORD_ID" ] && [ ! -z "$A_RECORD_NAME" ]; then
			error "	- A_RECORD_ID or A_RECORD_NAME"
		fi
		exit 1;
	else
		msg "Environment variables seem to be setup correctly" 
	fi
}

setup() {
	
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
	echo "$SCRIPT_SCHEDULE \/script.sh  >> /var/log/script.log" | tee /crontab.txt 
	/usr/bin/crontab /crontab.txt
	
	# Link the output from '/script.sh >> /var/log/script.log' to stdout, this allows docker to see the log
	ln -sf /dev/stdout /var/log/script.log 
	msg "Setup complete"
	# msg "Starting crond"
	/usr/sbin/crond -f # -l $LOGGING_LEVEL
}
setup
