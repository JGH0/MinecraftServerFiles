# Third-Party Notices

This repository is a **Minecraft server setup**: it bundles the mods needed to run
that server so it can be deployed reproducibly. The mods in `mods/` are **not**
covered by this project's MIT license (see `LICENSE`). Each is the work of its
own author and remains under its own terms, as listed below.

License information was read from each jar's `mods.toml` / `fabric.mod.json`
metadata and any bundled license file. Where a jar declares "All Rights
Reserved" or does not specify a license, **no license to redistribute is granted
by this repository** — those files are included solely so this specific server
stack can be built and deployed.

If you intend to reuse or redistribute this repository, you are responsible for
checking each mod's terms with its author.

---

## All Rights Reserved

Redistribution is **not** granted by these licenses. Do not assume you may copy
these jars elsewhere.

| Mod | Author | Notes |
|-----|--------|-------|
| Balm | BlayTheNinth | Permissions: <https://mods.twelveiterations.com/permissions> |
| Waystones | BlayTheNinth | Permissions: <https://mods.twelveiterations.com/permissions> |
| Sophisticated Core | P3pp3rF1y | |
| Sophisticated Storage | P3pp3rF1y, Ridanisaurus | |
| Echo Chest | Fuzs | Metadata: MPL-2.0; bundled assets: All Rights Reserved |
| Puzzles Lib | Fuzs | Metadata: MPL-2.0 |
| Simple Voice Chat | Max Henkel | <https://modrepo.de/minecraft/voicechat/overview> |
| Waystones Teleport Pets | precisemodpacker | |
| Mo' Foods | — | <https://modrinth.com/datapack/mo-foods> |
| Ender Villages | BaffledBanana87 | |
| Egg Delight | Ross2750 | |
| Echoes of the End (Structures) | SmartStreamLabs | |
| Leon's Spooky Music | Taknax, Leon | License field: "Not specified" |
| End Villager Trader | Leonxkingx, MadeBySanny | License field: "Not specified" |
| BetterGuard | SOLEA PIXEL STUDIO | CC0 file bundled; metadata: "SOLEA PIXEL LICENSE" — <https://soleapixel.com> |

## MIT

| Mod | Author | Notes |
|-----|--------|-------|
| AntiXray | Drex | |
| BlueMap | BlueMap contributors | See <https://bluemap.bluecolored.de> |
| Chunk Claim | — | |
| Farmer's Delight | vectorwing | |
| Ferrite Core | malte0811 | |
| flib | Lothrazar | |
| Just Enough Items (JEI) | mezz | |
| Carpet: NeoForged | chililisoup | |
| Polaroid Camera | CyborgPigeon | |
| Real Filing Reborn | MisterD Modding | |
| Secure Trade | Navielon | |
| Spud's Shops | lucab | |
| Tpa Teleport | Itamio | |
| **Player Blocker** | **JGH** (this project's own mod) | |

## Apache-2.0

| Mod | Author |
|-----|--------|
| Forgified Fabric API | Sinytra, FabricMC |

Apache-2.0 requires that this notice be retained. Full text: <https://www.apache.org/licenses/LICENSE-2.0>

## LGPL-2.1

| Mod | Author |
|-----|--------|
| Trade Refresh | lcy0x1 |

## Other

| Mod | Author | License |
|-----|--------|---------|
| Lush Cave Trader | Leonxkingx | Academic Free License v3.0 |
| Storage Network | Lothrazar | Declared as "SeeGithub" — check the upstream repository |
| Sinytra Connector | Sinytra | No license field in jar; see <https://github.com/Sinytra/Connector> |

---

## Minecraft and NeoForge

This project runs **Minecraft**, which is proprietary software of Mojang
Studios / Microsoft. No Minecraft code is distributed in this repository; the
server downloads it at runtime, and users must accept the
[Minecraft EULA](https://aka.ms/MinecraftEULA). **NeoForge** is distributed
under the LGPL-2.1. Neither is covered by this project's MIT license.

## Modpack / server use

This repository exists to run a private-then-public community server. If you are
an author of one of the mods above and would prefer your jar not be included
here, please open an issue and it will be removed.
