# Minecraft Server Files

A NeoForge 1.21.1 modded Minecraft server ready to deploy as a Portainer stack.

**One image runs everything:** the Minecraft server *and* the website
(static site + BlueMap 3D map), served by nginx.

## What runs where

| Port | Protocol | Service |
|------|----------|---------|
| 25565 | TCP | Minecraft server |
| 24454 | UDP | Simple Voice Chat |
| 8080  | TCP | Website (`/`) + BlueMap (`/map/`) |

Inside the container, nginx listens on `8080` and reverse-proxies `/map/`
to BlueMap's integrated webserver on `8100` (never exposed directly).

The image uses a thin custom entrypoint (`scripts/entrypoint.sh`) that
prepares the webroot, starts nginx, and then execs the stock itzg `/start`.
So one container serves both the game and the site.

## Mods Included

| Mod | Description |
|-----|-------------|
| Waystones + Teleport Pets | Fast travel system |
| Sophisticated Storage + Core | Upgradable storage |
| Storage Network | Remote storage access |
| Farmers Delight + Egg Delight | Cooking/farming |
| Simple Voice Chat | Proximity voice (UDP 24454) |
| Echo Chest / Echoes of the End | End-game structures |
| End Villages + Trader | End dimension expansion |
| Chunk Claim | Land claiming |
| Secure Trade / Trade Refresh | Better villager trading |
| Spudacious Shops | Player shops |
| Connector + Forgified Fabric API | Runs Fabric mods on NeoForge |
| Mo' Foods | More food variety |
| Lush Cave Trader | Lush cave content |
| Polaroid Camera | Take in-game photos |
| Puzzles Lib | Library mod |
| Balm / Flib | Library mods |
| Real Filing Reborn | Better file cabinets |
| TPA Teleport | Teleport commands |
| Spooky Music | Atmospheric music |
| **BlueMap** | Live 3D web map (overworld, nether, end) |

## Deployment (Portainer)

1. Add this repo as a custom template or stack:
   - **Repository URL:** `git@github.com:JGH0/MinecraftServerFiles`
   - **Branch:** `main`

2. Configure ports (if you have a reverse proxy that forwards ports, adjust in the stack):

   | Service | Container Port | Protocol |
   |---------|---------------|----------|
   | Minecraft | 25565 | TCP |
   | Voice Chat | 24454 | UDP |
   | Website | 8080 | TCP |

3. Deploy the stack.

### Important: your world volume & container name

- **Volume:** the stack declares `mc-data` as an **external** volume, so Compose
  attaches to your existing world instead of creating a fresh
  `minecraftserverfiles_mc-data`. If that volume is ever missing:
  `docker volume create mc-data`.
- **Container name:** the service uses `container_name: modded-mc-server`.
  If a container with that name already exists (e.g. your current one), remove
  it first or the deploy fails with a name conflict:
  ```bash
  docker rm -f modded-mc-server
  ```
  Your world is safe in the `mc-data` volume — removing the *container* does
  not delete the volume.

## Local Build & Test

```bash
cd ~/MinecraftServerFiles
docker compose build
docker compose up -d
```

Then open <http://localhost:8080/> for the site and
<http://localhost:8080/map/> for the BlueMap.

## Updating Mods

`mods.zip` on the website is **rebuilt automatically on every image build**,
so it always matches the `mods/` folder that shipped with the running image.

1. Replace `.jar` files in the `mods/` directory
2. Update configs in `config/` if needed
3. Commit and push:
   ```bash
   git add mods/ config/
   git commit -m "Update mods: <description>"
   git push
   ```
4. In Portainer, pull the stack's latest commit and rebuild

## BlueMap (3D map)

- **Mod:** `mods/bluemap-5.7-neoforge.jar` — the newest BlueMap NeoForge build
  that supports Minecraft **1.21.1** (later releases target NeoForge 26.x /
  Java 25).
- **Config:** `config/bluemap/` — one map per dimension (`maps/world.conf`,
  `maps/world_the_nether.conf`, `maps/world_the_end.conf`).
- **Rendered data:** `/data/bluemap/web` inside the `mc-data` volume, so the
  render survives restarts.
- **Viewing:** <http://localhost:8080/map/> via the nginx reverse-proxy.

Useful in-game commands: `/bluemap` (status), `/bluemap reload`,
`/bluemap render`.

> **First boot:** BlueMap downloads the Minecraft client jar (~26 MB) and
> renders the *entire* existing world once. That first render is CPU-heavy and
> can take hours on a big world; afterwards it only re-renders chunks that
> change. Check progress with `/bluemap` in-game or in the container logs.

## World copies

World snapshots are made on the host with `scripts/mc-backup.sh`
(copies the Docker `mc-data` volume to `~/Documents/McBackup/<timestamp>/`).

They are **not offered as public downloads** — the website tells visitors to
request a copy on Discord or in-game. See `website/README.md` for how
snapshots are published if you ever want to open them up again.

## Notes

- The server starts with **6 GB RAM** allocated — adjust `MEMORY` in `docker-compose.yml` if needed
- You can set server.properties values via environment variables in the stack
