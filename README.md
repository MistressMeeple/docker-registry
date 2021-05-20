# docker-registry
my docker registry
### Cron
-----
Simple Docker container to fascilitate cron jobs, runs alpine
Script.sh should be included
Env Arg | Description | Default 
--|--|--
LOGGING_LEVEL|Chooses the logging level for crond|8
SCRIPT_SCHEDULE|Defines the frequency that the cron job will run, this is passed directly to cron so it should be in that format|*/5 * * * *


### Dynamic DNS
-----
Expanding on the cron, runs the included script every 5 mins to post ip changes to Cloud-Flare wesbite for DNS changes.
Credit to [dcerisano/cloudflare-dynamic-dns](https://github.com/dcerisano/cloudflare-dynamic-dns), I just adapted this to suit my needs as a docker container. For instructions on how to set it up, go there too. 

Env Arg | Description | Default
--|--|--
LOGGING_LEVEL | (Same as cron) | (Same as cron)
SCRIPT_SCHEDULE|(Same as cron)| (Same as cron)
ZONE_ID| The Zone ID of Cloudflare| NULL
API_TOKEN | Cloud-Flare account API-Token<br> *REQUIRES* 'DNS:Edit' permissions. |NULL
A_RECORD_NAME|Name of the A-Record to change in the DNS list|NULL
A_RECORD_ID|ID of the A-Record to change in the DNS list |NULL

A_RECORD_ID can be retrieved with the following command
```
curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=dynamic"
    -H "Host: api.cloudflare.com"
    -H "User-Agent: ddclient/3.9.0"
    -H "Connection: close"
    -H "Authorization: Bearer $API_TOKEN"
```
See also: https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records
