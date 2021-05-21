FROM alpine
RUN apk add --update curl && apk add --update apk-cron && apk add --update jq && rm -rf /var/cache/apk/*

ENV LOGGING_LEVEL="8"
ENV SCRIPT_SCHEDULE="*/5 * * * *"
ENV ZONE_ID=""
ENV API_TOKEN=""
ENV A_RECORD_NAME=""
ENV A_RECORD_ID=""
ENV CACHED_IP_RECORD="/tmp/cached-ip"

ADD script.sh /
CMD ["/docker-entrypoint.sh"]
