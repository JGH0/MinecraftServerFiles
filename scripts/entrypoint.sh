#!/bin/bash
# ============================================================
# entrypoint.sh — runs inside the Minecraft container
#
# Wraps the normal itzg /start so that nginx (the website + BlueMap
# reverse-proxy) comes up alongside the Minecraft server.
#
# The itzg image has no "init.d" hook for long-running side services,
# so we prepare the webroot, start nginx in the background, and then
# hand over to /start exactly as the base image would.
# ============================================================
set -u

WEB_ROOT=/usr/share/nginx/html
SRC_ROOT=/website

log() { echo "[website] $*"; }

prepare_webroot() {
    log "Preparing webroot at $WEB_ROOT …"
    mkdir -p "$WEB_ROOT"

    # Sync the static site. --delete keeps the webroot in step with the repo.
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete --exclude '.git' "$SRC_ROOT/" "$WEB_ROOT/"
    else
        cp -a "$SRC_ROOT/." "$WEB_ROOT/" 2>/dev/null || true
    fi

    # Downloads: world backups are bind-mounted read-only by docker-compose
    # at /usr/share/nginx/downloads. Create it so nginx is happy when the
    # mount is absent (stand-alone `docker run`).
    mkdir -p /usr/share/nginx/downloads

    # The image bakes a mods.zip built from /mods at build time. Seed it in
    # when there isn't one yet, so mods.zip is always downloadable even on a
    # bare `docker run` or a fresh checkout where website/downloads/ is empty.
    if [ -f /ui/downloads/mods.zip ] && [ ! -f /usr/share/nginx/downloads/mods.zip ]; then
        cp /ui/downloads/mods.zip /usr/share/nginx/downloads/mods.zip 2>/dev/null || true
    fi

    # NOTE: do not pre-create /data/bluemap here. This function runs as root,
    # but BlueMap runs as the "minecraft" user — creating it as root would
    # leave it unwritable and break the render + Mojang resource download.
    # BlueMap creates the folder itself.

    # Small runtime marker the site can read.
    cat > "$WEB_ROOT/data/runtime.json" <<EOF
{
  "generatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mapUrl": "/map/",
  "serverIp": "mc.hallenbarter.org"
}
EOF
}

start_nginx() {
    if ! command -v nginx >/dev/null 2>&1; then
        log "nginx is not installed — website will not be served."
        return 0
    fi
    log "Starting nginx (website on :8080, /map/ -> BlueMap on :8100)…"
    nginx -g "daemon on;" 2>/dev/null || nginx || log "nginx failed to start"
}

# Copy Carpet scarpet scripts into the world once it exists. The itzg image
# has no pre-server hook, so we wait in the background for /data/world to be
# created (first boot generates it) and then drop the scripts in.
sync_scarpet_scripts() {
    local dst=/data/world/scripts
    for _ in $(seq 1 60); do
        if [ -d /data/world ]; then
            mkdir -p "$dst"
            cp -n /scripts/*.sc "$dst/" 2>/dev/null || true
            log "Copied scarpet scripts to $dst"
            return 0
        fi
        sleep 5
    done
    log "world dir never appeared — scarpet scripts not copied"
}

prepare_webroot
start_nginx
sync_scarpet_scripts &

# Hand over to the stock itzg entrypoint.
exec /start "$@"
