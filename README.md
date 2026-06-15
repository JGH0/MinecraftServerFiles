# Minecraft Server Files

A NeoForge 1.21.1 modded Minecraft server ready to deploy as a Portainer stack.

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

## Deployment (Portainer)

1. Add this repo as a custom template or stack:
   - **Repository URL:** `git@github.com:JGH0/MinecraftServerFiles`
   - **Branch:** `main`

2. Configure ports (if you have a reverse proxy that forwards ports, adjust in the stack):

   | Service | Container Port | Protocol |
   |---------|---------------|----------|
   | Minecraft | 25565 | TCP |
   | Voice Chat | 24454 | UDP |

3. Deploy the stack.

## Local Build & Test

```bash
cd ~/MinecraftServerFiles
docker compose build
docker compose up -d
```

## Updating Mods

1. Replace `.jar` files in the `mods/` directory
2. Update configs in `config/` if needed
3. Commit and push:
   ```bash
   git add mods/ config/
   git commit -m "Update mods: <description>"
   git push
   ```
4. In Portainer, pull the stack's latest commit and rebuild

## World Data

The initial world (`world/` directory) is a copy of the test save. Live world data persists in the Docker named volume `mc-data`.

## Notes

- The server starts with **6 GB RAM** allocated — adjust `MEMORY` in `docker-compose.yml` if needed
- You can set server.properties values via environment variables in the stack