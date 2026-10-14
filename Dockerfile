FROM itzg/minecraft-server:latest

# ---------------------------------------------------------------------------
# One image runs both the Minecraft server and the website:
#   * Minecraft (NeoForge 1.21.1) on 25565/tcp  + voice chat 24454/udp
#   * nginx on 8080/tcp  -> static site + BlueMap at /map/
#
# The itzg image auto-copies files from /mods and /config into /data on first
# start. World data is NOT baked in — the server generates it into the
# persistent volume.
# ---------------------------------------------------------------------------

# --- system packages for the bundled webserver -----------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx rsync zip unzip ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# --- mods (includes BlueMap 5.7 NeoForge) ----------------------------------
COPY mods/ /mods/
COPY config/ /config/

# --- utility + entrypoint scripts ------------------------------------------
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# --- website ---------------------------------------------------------------
# Baked into the image; entrypoint.sh syncs it into /usr/share/nginx/html on
# boot. Rebuild the image to publish site changes.
COPY website/ /website/
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# --- mods.zip for the downloads page ---------------------------------------
# Built fresh on every image build so the zip always matches the mods/ folder
# that shipped with this build. entrypoint.sh seeds it into the webroot when
# the host bind-mount doesn't already provide one.
RUN mkdir -p /ui/downloads && \
    (cd / && zip -q -r /ui/downloads/mods.zip mods) && \
    echo "built mods.zip from /mods: $(ls -l /ui/downloads/mods.zip | awk '{print $5}') bytes"

# --- entrypoint ------------------------------------------------------------
# Starts nginx (website + BlueMap proxy), then execs the stock itzg /start.
ENTRYPOINT ["/scripts/entrypoint.sh"]
