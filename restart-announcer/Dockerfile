FROM alpine:3.20

RUN apk add --no-cache \
        mcrcon \
        bash \
        tzdata \
        dcron \
        su-exec

ENV TZ=Europe/Zurich

# Install the restart script
COPY restart.sh /usr/local/bin/restart-server
RUN chmod +x /usr/local/bin/restart-server

# Set up cron
COPY crontab /var/spool/cron/crontabs/root

# Entrypoint: start cron and keep alive
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]
