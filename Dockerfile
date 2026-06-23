FROM itzg/minecraft-server:latest

# Copy mods and configs into the image
# The itzg image auto-copies these from /mods and /config into /data on first start
# World is NOT baked in — the server generates a fresh one and persists it in the volume
COPY mods/ /mods/
COPY config/ /config/

# Copy utility scripts (restart announcer, etc.)
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && \
    # Copy scarpet init script so it runs on every container start
    mkdir -p /docker-entrypoint-init.d/ && \
    cp /scripts/init-scarpet.sh /docker-entrypoint-init.d/
