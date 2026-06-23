#!/bin/bash
# Copies Carpet scarpet scripts to the persistent data volume on every start
set -e

SCARPET_SRC=/scripts/*.sc
SCARPET_DST=/data/scripts

if ls $SCARPET_SRC 2>/dev/null; then
    mkdir -p "$SCARPET_DST"
    cp -n /scripts/*.sc "$SCARPET_DST/"
    echo "[init-scarpet] Copied scarpet scripts to $SCARPET_DST"
fi
