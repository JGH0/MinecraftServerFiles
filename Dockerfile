FROM itzg/minecraft-server:latest

# Copy mods, config, and initial world into the image
# The itzg image auto-copies /mods and /config into /data on first start
COPY mods/ /mods/
COPY config/ /config/
COPY world/ /data/world/
