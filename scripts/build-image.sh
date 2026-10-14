#!/bin/bash
# ============================================================
# build-image.sh — build the server+website image on this host
#
# This repo's stack runs a PREBUILT image (no build: in
# docker-compose.yml) because Portainer's Agent environment cannot
# perform compose builds (Portainer bug #13255):
#   "listing workers for Build ... frame header looked like an
#    HTTP/1.1 header"
#
# So: run this script on the host whenever the Dockerfile, mods,
# config or website change, then redeploy the stack in Portainer.
#
# Usage:
#   ./scripts/build-image.sh
#   # then in Portainer: Stacks -> your stack -> Update the stack
#   # (enable "Re-pull image" OFF — it's a local image)
# ============================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-modded-mc-server:latest}"

echo "==> Building $IMAGE from $REPO_DIR"
cd "$REPO_DIR"

# BuildKit (buildx) is used because it is what Docker 29 prefers, and it is
# what the daemon exposes to Portainer. Falls back to the classic builder if
# buildx is unavailable.
if docker buildx version >/dev/null 2>&1; then
    docker build -t "$IMAGE" .
else
    DOCKER_BUILDKIT=0 docker build -t "$IMAGE" .
fi

echo "==> Built:"
docker images "$IMAGE" --format '    {{.Repository}}:{{.Tag}}  {{.Size}}  {{.CreatedSince}}'
echo
echo "==> Next: redeploy the stack in Portainer to pick up the new image."
