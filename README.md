# docker-registry
my docker registry
### Cron
Simple Docker container to fascilitate cron jobs, runs alpine
Script.sh should be included
Env Arg | Description | Default 
--|--|--
LOGGING_LEVEL|Chooses the logging level for crond|8
SCRIPT_SCHEDULE|Defines the frequency that the cron job will run, this is passed directly to cron so it should be in that format|*/5 * * * *


