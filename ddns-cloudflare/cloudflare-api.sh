#!/bin/sh

function update_record_name_env() { 
    local RESULT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
        -H "content-type: application/json" \
        -H "Authorization: Bearer $API_TOKEN"
    )
    A_RECORD_NAME=$(echo "$RESULT" | jq -r .result[0].name) 
    echo "Updated A_RECORD_NAME: $A_RECORD_NAME" >&2
}

function update_record_ID_env(){
	local RESULT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A$name=$A_RECORD_NAME" \
    	-H "content-type: application/json" \
		-H "Authorization: Bearer $API_TOKEN"
    )
	A_RECORD_ID=$(echo "$RESULT" | jq -r .result[0].id)
    echo "Updated A_RECORD_ID: $A_RECORD_NAME" >&2
}
function update_record_env() {

    # If ID is not set then pull by name
    if [ ! -z "$A_RECORD_ID"  &&  -z "$A_RECORD_NAME" ]; then
        update_record_name_env
    #If Name is not set then pull by ID
    elif [  -z "$A_RECORD_ID"  && ! -z "$A_RECORD_NAME" ]; then
        update_record_ID_env
    fi
}
function update_cached_ip() {

    local RESULT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
        -H "content-type: application/json" \
        -H "Authorization: Bearer $API_TOKEN"
    )
    echo "$(echo "$RESULT" | jq -r .result[0].content)" | tee "$CACHED_IP_RECORD"
    echo "Updated Cached IP: "$(cat "$CACHED_IP_RECORD")>&2
}
