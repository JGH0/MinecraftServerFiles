#!/bin/bash
# ============================================================
# refresh-downloads.sh — mc.hallenbarter.org website
#
# 1. Re-zips new/changed world backups from the backup folder
#    into downloads/ (skips work when the zip is up to date).
# 2. Regenerates data/backups.json (the downloads page index).
#
# NOTE: mods.zip is NOT built here anymore — it is baked into the
#       Docker image on every build (see the repo root Dockerfile),
#       so it always matches the running server's mods/ folder.
#
# World copies are "on request" these days, so this script only
# matters if you decide to publish backup zips again.
#
# Usage:
#   ./scripts/refresh-downloads.sh                 # default paths
#   BACKUP_SRC=/path/to/McBackup ./scripts/refresh-downloads.sh
#
# The downloads page renders data/backups.json via JS — no rebuild needed.
# ============================================================
set -euo pipefail

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_SRC="${BACKUP_SRC:-$HOME/Documents/McBackup}"
DL_DIR="$SITE_DIR/downloads"
DATA_DIR="$SITE_DIR/data"

mkdir -p "$DL_DIR" "$DATA_DIR"

echo "==> Backing up zips in: $DL_DIR"
echo "==> Backup source:      $BACKUP_SRC"

# ---------- world backups ----------
shopt -s nullglob
for dir in "$BACKUP_SRC"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_*/; do
    name="$(basename "$dir")"
    zipfile="$DL_DIR/$name.zip"
    if [ ! -f "$zipfile" ] || [ "$(find "$dir" -newer "$zipfile" -print -quit 2>/dev/null)" != "" ]; then
        echo "  - zipping $name (this can take a while, the world is big)…"
        (cd "$BACKUP_SRC" && zip -q -r "$zipfile" "$name" -x '*_data_tmp*')
    else
        echo "  - $name.zip is up to date"
    fi
done

# ---------- regenerate the download index ----------
echo "==> Writing data/backups.json …"
python3 - "$DL_DIR" "$DATA_DIR" <<'PY'
import json, os, re, sys, datetime

dl_dir, data_dir = sys.argv[1], sys.argv[2]
pattern = re.compile(r"^(\d{4}-\d{2}-\d{2})_(\d{2})-(\d{2})-(\d{2})\.zip$")

files = []
for fn in os.listdir(dl_dir):
    m = pattern.match(fn)
    if not m:
        continue
    path = os.path.join(dl_dir, fn)
    size = os.path.getsize(path)
    stamp = datetime.datetime.strptime(m.group(1) + " " + m.group(2) + ":" + m.group(3) + ":" + m.group(4), "%Y-%m-%d %H:%M:%S")
    files.append({
        "type": "world",
        "title": "World copy — " + stamp.strftime("%Y-%m-%d %H:%M"),
        "date": stamp.strftime("%Y-%m-%d %H:%M"),
        "file": fn,
        "url": "downloads/" + fn,
        "sizeBytes": size,
        "sizeLabel": "full world save",
        "desc": "Full snapshot of the live server volume: overworld, nether, end, plus server state. "
                "Load it as a single-player world or use it to restore the server."
    })

files.sort(key=lambda f: f["file"], reverse=True)
out = {"generatedAt": datetime.datetime.now().isoformat(timespec="seconds"), "files": files}
with open(os.path.join(data_dir, "backups.json"), "w") as fh:
    json.dump(out, fh, indent=2)
    fh.write("\n")

print("  -> {} backup(s) listed".format(len(files)))
PY

echo "==> Done."
