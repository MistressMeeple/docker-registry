FROM alpine
RUN apk add --update curl && apk add --update apk-cron && rm -rf /var/cache/apk/*

ENV LOGGING_LEVEL="8"
ENV SCRIPT_SCHEDULE="*/5 * * * *"
ENV ZONE_ID=""
ENV API_TOKEN=""
ENV A_RECORD_NAME=""
ENV A_RECORD_ID=""

ADD script.sh /

RUN	touch /tmp/ip && \
    echo "#!/bin/sh" | tee /entry.sh && \
    echo "/usr/sbin/crond -f -l $LOGGING_LEVEL" | tee -a /entry.sh && \
    echo "$SCRIPT_SCHEDULE /script.sh  >> /var/log/script.log" | tee /crontab.txt && \
    ln -sf /dev/stdout /var/log/script.log \ 
    chmod 755 /script.sh /entry.sh \
    /usr/bin/crontab /crontab.txt
    
CMD ["/entry.sh"]
