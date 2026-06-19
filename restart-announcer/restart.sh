#!/bin/bash
set -e

# ─── Configuration ───────────────────────────────────────────────────────────
RCON_HOST="${RCON_HOST:-minecraft}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-changeme}"

MCRCON="mcrcon -H $RCON_HOST -P $RCON_PORT -p $RCON_PASSWORD"

# ─── Warnings before shutdown ────────────────────────────────────────────────
announce() {
    $MCRCON say "§6[Server] §eServer restart in $1 minute(s)! §7Save your builds."
}

announce "5"
echo "  [restart-announcer] Warning: 5 minutes"
sleep 120

announce "3"
echo "  [restart-announcer] Warning: 3 minutes"
sleep 120

announce "1"
echo "  [restart-announcer] Warning: 1 minute"
sleep 50

$MCRCON say "§6[Server] §cServer restarting NOW! §eSee you in a minute \u2728"
echo "  [restart-announcer] Stopping server..."
sleep 10

# ─── Graceful stop ───────────────────────────────────────────────────────────
$MCRCON stop
echo "  [restart-announcer] /stop sent. Docker will restart the container automatically."

# Wait for the server container to actually go down so we don't
# keep running forever if cron fires again
sleep 60
echo "  [restart-announcer] Done."
