FROM alpine

RUN apk add --update apk-cron && rm -rf /var/cache/apk/*

ADD script.sh /script.sh
ENV LOGGING_LEVEL="8"
ENV SCRIPT_SCHEDULE="*/5 * * * *"
RUN     echo "#!/bin/sh" | tee /entry.sh && \
        echo "/usr/sbin/crond -f -l $LOGGING_LEVEL" | tee -a /entry.sh && \
        echo "$SCRIPT_SCHEDULE /script.sh  >> /var/log/script.log" | tee /crontab.txt

RUN chmod 755 /script.sh /entry.sh
RUN /usr/bin/crontab /crontab.txt

CMD ["/entry.sh"]
