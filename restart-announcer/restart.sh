#!/bin/bash
set -e

# ─── Safety check: only run between 01:00 and 02:30 local time ───────────────
HOUR=$(date +%-H)
if [ "$HOUR" -ne 1 ] && [ "$HOUR" -ne 2 ]; then
    echo "  [restart-announcer] Current hour is $HOUR — not in restart window (01:00–02:30). Exiting."
    exit 0
fi

MINUTE=$(date +%-M)
if [ "$HOUR" -eq 2 ] && [ "$MINUTE" -gt 30 ]; then
    echo "  [restart-announcer] Past 02:30 — not in restart window. Exiting."
    exit 0
fi

# ─── Configuration ───────────────────────────────────────────────────────────
RCON_HOST="${RCON_HOST:-minecraft}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:-changeme}"

MCRCON="mcrcon -H $RCON_HOST -P $RCON_PORT -p $RCON_PASSWORD"

echo "  [restart-announcer] Time check passed. Starting restart sequence..."

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

sleep 60
echo "  [restart-announcer] Done."
