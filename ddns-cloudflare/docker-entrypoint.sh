#!/bin/sh

set -e

# logging functions
println() {
	type="$1"; shift
	# accept argument string or stdin
	text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	
	printf '[%5s] [Entrypoint] %s\n' "$type" "$text"
}>&2
log() {
	println " log " "$@"
}
warn() {
	println " warn" "$@"
}
error() {
	println "error" "$@"
}

env_from_file(){
	log "[Env-Arg] Starting checks on $1"
	#if unset
	if [ "${1:-}" ]; then 
		log "[Env-Arg]   $1 is unset, attempting to pull from ${1}_FILE"; 
		file_var=$(echo \$${1}_FILE)
		if [ "${file_var:-}" ]; then
			log "[Env-Arg]   $file_var has been set" 
			file_loc=$(eval echo ${file_var})
			if  [ -f "${file_loc}" ]; then 
				log "[Env-Arg]   File exists, now putting the contents into $1"
				export "$(echo ${1})"=$(eval "cat $(echo $(echo \$${1}_FILE))")
				unset $(echo "$file_var" | sed 's/\$//')
			else
				error "[Env-Arg]   $file_loc does NOT exist"
			fi
		else
			error "[Env-Arg]   '$file_var' has NOT been set."
		fi
	else
		log "[Env-Arg]   $1 is already set, skipping"
	fi
}

env_var_check() {
	if [ "$ZONE_ID" ] &&  [ "$API_TOKEN" ] && { [ "$A_RECORD_ID" ] || [ "$A_RECORD_NAME" ]; }  then
		log "Environment variables seem to be setup correctly" 
	else
		error "Environment variables are missing! Cannot start the container without these variables. " 
		error "Ensure you have the following set correctly: "
		if [ -z "$ZONE_ID" ]; then
			error "	- ZONE_ID"
		fi
		if [ -z "$API_TOkEN" ]; then
			error "	- API_TOKEN"
		fi	
		if [ -z  "$A_RECORD_ID" ] || [ -n "$A_RECORD_NAME" ]; then
			error "	- A_RECORD_ID or A_RECORD_NAME"
		fi
		error "Alternatively set each of the required EnvArgs with a file (Docker secrets) by appening '_FILE' to the definition"
		error "e.g. '-e A_RECORD_NAME_FILE=/run/secrets/A_RECORD_NAME.txt'"
		exit 1;
	fi
}

update_record_name_env() { 
    RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
        -H "content-type: application/json" \
        -H "Authorization: Bearer $API_TOKEN"
    )
    A_RECORD_NAME=$(echo "$RESULT" | jq -r .result[0].name) 
    log "Updated A_RECORD_NAME: $A_RECORD_NAME" >&2
}

update_record_ID_env(){
	RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$A_RECORD_NAME" \
		-H "content-type: application/json" \
		-H "Authorization: Bearer $API_TOKEN"
    )
    A_RECORD_ID=$(echo "$RESULT" | jq -r .result[0].id)
    log "Updated A_RECORD_ID: $A_RECORD_NAME" >&2
}

update_record_env() {

    # If ID is not set then pull by name
    if [ ! -z "$A_RECORD_ID" ]  && [ -z "$A_RECORD_NAME" ]; then
        update_record_name_env
    #If Name is not set then pull by ID
    elif [  -z "$A_RECORD_ID" ] && [ ! -z "$A_RECORD_NAME" ]; then
        update_record_ID_env
    fi
}

update_cached_ip() {

    RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
        -H "content-type: application/json" \
        -H "Authorization: Bearer $API_TOKEN"
    )
    echo "$(echo $RESULT | jq -r .result[0].content)" | tee "$CACHED_IP_RECORD"
    log "Updated Cached IP: $(cat '$CACHED_IP_RECORD')">&2
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
	# Run the scripts to update local records from upstream
	update_record_env
	update_cached_ip
	# Create the crontab file, and set it up
	echo "$SCRIPT_SCHEDULE \/script.sh  >> /var/log/script.log" | tee /crontab.txt 
	/usr/bin/crontab /crontab.txt
	
	# Link the output from '/script.sh >> /var/log/script.log' to stdout, this allows docker to see the log
	ln -sf /dev/stdout /var/log/script.log 
	log "Setup complete"
}
setup
log "Starting crond"
/usr/sbin/crond -f -l $LOGGING_LEVEL
