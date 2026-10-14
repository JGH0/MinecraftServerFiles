# mc.hallenbarter.org — website

Static website for the *Slightly Modded* Minecraft server.
Split into pages + shared assets (no build step, no framework — open the files and go).

The site is baked into the Docker image and served by nginx on port **8080**
alongside the Minecraft server (see the repo root `Dockerfile` and
`docker-compose.yml`).

## Structure

```
index.html        Home: status, quick facts, how to join, rules, 3D map
mods.html         Full searchable mod list (35 jars) + roadmap
downloads.html    Modpack download + "request a world copy" info
404.html          Void-themed 404
assets/css/style.css   Shared styles (one source of truth)
assets/js/main.js      Particles, live status, copy buttons, mod filter, downloads renderer
assets/img/favicon.svg
data/backups.json      Download index — GENERATED, do not edit by hand
data/runtime.json      Written by the container on boot
downloads/             mods.zip (baked into the image) + optional world zips
scripts/refresh-downloads.sh   Republish zips + regenerate the index (see below)
```

## Editing the obvious things

- Server address / status API / seed: top of `assets/js/main.js` → `CONFIG`.
- Rules / copy text: straight in the HTML of the relevant page.
- Mod list rows: `mods.html` table (keep `mod-name`/`mod-file` cells consistent).
- BlueMap lives at `/map/` (reverse-proxied to BlueMap's own webserver).

## The 3D map (BlueMap)

BlueMap is a mod on the Minecraft server (`mods/bluemap-5.7-neoforge.jar`)
with its config in `config/bluemap/`. It renders the overworld, nether and
end and serves a web-app on `:8100` inside the container. nginx proxies
`/map/` to it, so visitors just use `/map/` — no extra port to publish.

## Keeping the modpack fresh

`mods.zip` is **rebuilt automatically on every image build** (see the
Dockerfile), so it always matches the `mods/` folder of the running image.
Nothing to do by hand — just rebuild the stack after changing mods.

## World copies (on request)

World snapshots are made on the host with the repo's
[`scripts/mc-backup.sh`](../scripts/mc-backup.sh), which copies the Docker
`mc-data` volume to `~/Documents/McBackup/<timestamp>/`.

They are **not published as public downloads** — the downloads page tells
visitors to ask on Discord or in-game. If you ever want to open them up
again, drop the zips into `downloads/` and run:

```bash
./scripts/refresh-downloads.sh
```

This zips new backups into `downloads/` (skips up-to-date ones) and
regenerates `data/backups.json`. `BACKUP_SRC` overrides the source path.

## Deploying

The image serves the site and the map on port 8080. For a public hostname,
point an nginx / nginx-proxy-manager proxy host at `<host>:8080`.

- Dev preview without Docker: `python3 -m http.server 8080` inside this folder.
  BlueMap (`/map/`) only works through the container.
- Downloads can be multi-GB — nginx in the image is already configured for
  large transfers.
- The live status widget calls the public mcstatus API
  (`api.mcsrvstat.us`) from the browser — no server-side part needed.

Source of truth for the server config is
https://github.com/JGH0/MinecraftServerFiles
