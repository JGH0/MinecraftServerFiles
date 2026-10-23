#!/bin/bash
# ============================================================
# gen-rcon-secret.sh — create the RCON password file on this host
#
# docker-compose.yml mounts ./secrets/rcon_password into the container
# and passes its path via RCON_PASSWORD_FILE. That file lives outside
# git (secrets/ is .gitignore'd), so the password never appears in the
# repository or its history.
#
# The file must exist before the container starts, otherwise the itzg
# image logs "Initial RCON password file ... does not seems to exist"
# and exits. Run this once on the host, then deploy.
#
# Usage:
#   ./scripts/gen-rcon-secret.sh            # create if missing
#   ./scripts/gen-rcon-secret.sh --force    # rotate to a new password
# ============================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRET_DIR="$REPO_DIR/secrets"
SECRET_FILE="$SECRET_DIR/rcon_password"
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=1 ;;
        -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if [ -e "$SECRET_FILE" ] && [ "$FORCE" -eq 0 ]; then
    echo "==> $SECRET_FILE already exists — leaving it alone."
    echo "    (use --force to rotate, then redeploy the stack)"
    exit 0
fi

# `umask 077` so the file is created 0600 from the start — no window where
# a valid password sits on disk world-readable.
umask 077
mkdir -p "$SECRET_DIR"
# 32 hex chars: avoids shell-quoting issues if ever pasted by hand.
PASSWORD="$(openssl rand -hex 16)"
printf '%s\n' "$PASSWORD" > "$SECRET_FILE"
chmod 600 "$SECRET_FILE"

echo "==> Wrote a new RCON password to $SECRET_FILE (mode 600)"
echo
echo "    Connect with an RCON client using:"
echo "      address:  127.0.0.1:25575   (only after publishing the port;"
echo "                                    it is NOT exposed by default)"
echo "      password: $(cat "$SECRET_FILE")"
echo
echo "==> Next: redeploy the stack (Portainer: Update the stack)."
