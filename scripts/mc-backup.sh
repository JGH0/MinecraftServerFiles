#!/bin/bash
# ============================================================
# mc-backup.sh — copy the live Minecraft world out of Docker
#
# Copies the server's persistent Docker volume (mc-data) into a
# timestamped folder under $HOME/Documents/McBackup/ by default.
#
# These folders are what the website's downloads page turns into
# zips — see scripts/refresh-downloads.sh.
#
# Usage:
#   ./scripts/mc-backup.sh                    # default source + dest
#   SRC=/path/to/volume ./scripts/mc-backup.sh
#   DEST=/path/to/backups ./scripts/mc-backup.sh
#
# Run it on the host that runs the Docker stack. The server restarts
# daily at 01:55 with an in-game countdown — backing up right after
# that is a good habit, but cp is safe on a running server too.
# ============================================================
set -euo pipefail

# The world lives in the "mc-data" named volume (see docker-compose.yml).
SRC="${SRC:-/var/lib/docker/volumes/mc-data/_data}"
DEST="${DEST:-$HOME/Documents/McBackup/$(date '+%Y-%m-%d_%H-%M-%S')}"

if [ ! -d "$SRC" ]; then
    echo "error: source volume not found: $SRC" >&2
    echo "Set SRC=/path/to/mc-data/_data and try again." >&2
    exit 1
fi

mkdir -p "$DEST"

echo "==> Backing up world"
echo "    from: $SRC"
echo "    to:   $DEST"

# -a preserves ownership/permissions so the volume can be restored 1:1.
# sudo is needed because Docker volumes are root-owned.
if [ "$(id -u)" -ne 0 ]; then
    sudo cp -a "$SRC"/. "$DEST"/
else
    cp -a "$SRC"/. "$DEST"/
fi

echo "==> Done: $(du -sh "$DEST" 2>/dev/null | cut -f1) in $DEST"
echo "==> Next: run scripts/refresh-downloads.sh to publish it on the website."
