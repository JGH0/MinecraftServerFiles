FROM alpine:3.20 AS builder

RUN apk add --no-cache git build-base cmake
RUN git clone https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon
RUN cd /tmp/mcrcon && gcc -std=gnu11 -pedantic -Wall -O2 -o mcrcon mcrcon.c

# ── Final stage ──────────────────────────────────────────────────────────
FROM alpine:3.20

RUN apk add --no-cache bash tzdata dcron

# Copy the pre-built mcrcon binary
COPY --from=builder /tmp/mcrcon/mcrcon /usr/local/bin/mcrcon

# Copy the restart script
COPY restart.sh /usr/local/bin/restart-server
RUN chmod +x /usr/local/bin/restart-server

# Set up cron
COPY crontab /var/spool/cron/crontabs/root

# Entrypoint: start cron and keep container alive
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]
