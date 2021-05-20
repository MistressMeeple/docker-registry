#/usr/bin/env sh

# Provide variables with docker environment for the following: 
# $ZONE_ID
# $API_TOKEN
# $A_RECORD_NAME
# $A_RECORD_ID

# Retrieve the last recorded public IP address
IP_RECORD="/tmp/ip"
RECORDED_IP=`cat $IP_RECORD`

# Fetch the current public IP address
PUBLIC_IP=$(curl --silent https://api.ipify.org) || exit 1

#If the public ip has not changed, nothing needs to be done, exit.
if [ "$PUBLIC_IP" = "$RECORDED_IP" ]; then
    exit 0
fi
echo "IP has changed. Notifying Cloud-flare"
echo "\tcurrent: '"$PUBLIC_IP"'. previous: '"$RECORDED_IP"'"
# Otherwise, your Internet provider changed your public IP again.
# Record the new public IP address locally
echo $PUBLIC_IP > $IP_RECORD

# Record the new public IP address on Cloudflare using API v4
RECORD=$(cat <<EOF
{ "type": "A",
  "name": "$A_RECORD_NAME",
  "content": "$PUBLIC_IP",
  "ttl": 180,
  "proxied": false }
EOF
)
curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_RECORD_ID" \
     -X PUT \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_TOKEN" \
     -d "$RECORD"
