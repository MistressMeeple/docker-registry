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

env_from_file(){
	msg "[Env-Arg] Starting checks on $1"
	#if unset
	if [ "${1:-}" ]; then 
		msg "[Env-Arg]   $1 is unset, attempting to pull from ${1}_FILE"; 
		local file_var=$(echo \$${1}_FILE)
		if [ "${file_var:-}" ]; then
			msg "[Env-Arg]   $file_var has been set" 
			local file_loc=$(eval echo ${file_var})
			if  [ -f "${file_loc}" ]; then 
				msg "[Env-Arg]   File exists, now putting the contents into $1"
				export "$(echo ${1})"=$(eval "cat $(echo $(echo \$${1}_FILE))")
				unset $(echo "$file_var" | sed 's/\$//')
			else
				error "[Env-Arg]   $file_loc does NOT exist"
			fi
			#if [ ! -z "${1}_FILE" ] && [ -f "${1}_FILE" ]; then local content=$(eval "cat $(echo $(echo \$${1}_FILE))")msg "File extists and is updating env-var"msg "'$content'"			else	msg "File not found"		fi
		else
			error "[Env-Arg]   '$file_var' has NOT been set."
		fi
	else
		msg "[Env-Arg]   $1 is already set, skipping"
	fi
	#export "$(echo ${1})"=$(eval "cat $(echo $(echo \$${1}_FILE))")
}

env_var_check() {
	msg "$ZONE_ID"
	msg "$API_TOKEN"
	msg "$A_RECORD_ID"
	msg "$A_RECORD_NAME"
	if [ -z "$ZONE_ID" ] && [ -z "$API_TOKEN" ] &&  ( [ -z "$A_RECORD_ID" ] || [ -z "$A_RECORD_NAME" ] ); then
		msg "Environment variables seem to be setup correctly" 
	else
		error "Environment variables are missing! Cannot start the container without these variables. " 
		error "Ensure you have the following set correctly: "
		if [ -z "$ZONE_ID" ]; then
			error "	- ZONE_ID"
		fi
		if [ -z "$API_TOkEN" ]; then
			error "	- API_TOKEN"
		fi	
		if [ -z  "$A_RECORD_ID" ] || [ ! -z "$A_RECORD_NAME" ]; then
			error "	- A_RECORD_ID or A_RECORD_NAME"
		fi
		error "Alternatively set each of the required EnvArgs with a file (Docker secrets) by appening '_FILE' to the definition"
		error "e.g. '-e A_RECORD_NAME_FILE=/run/secrets/A_RECORD_NAME.txt'"
		exit 1;
	fi
}

setup() {
	env_from_file "ZONE_ID"
	env_from_file "API_TOKEN"
	env_from_file "A_RECORD_ID"
	env_from_file "A_RECORD_NAME"
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
	#/usr/sbin/crond -f # -l $LOGGING_LEVEL
}
setup
