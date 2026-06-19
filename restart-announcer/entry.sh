#!/bin/sh
set -e

# Start cron daemon in the background
crond -b -l 2

echo "[restart-announcer] Cron started. Waiting for 01:55 daily ..."

# Keep container alive
while true; do
    sleep 3600 &
    wait $!
done
