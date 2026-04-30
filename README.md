# L4D2 Linux Working Server

This repository documents a working **Left 4 Dead 2 Dedicated Server** setup on Linux.

The final working setup uses a **native Linux server install** with:

- Left 4 Dead 2 Dedicated Server
- MetaMod:Source
- SourceMod
- Versus mode configuration
- `screen` for keeping the server running in the background

There is also an older Docker Compose setup included, but that setup is only recommended for a **vanilla server without mods**.

---

## Important Notes

### Recommended Setup

Use the **native Linux setup** if you want:

- MetaMod
- SourceMod
- Admin menu
- Plugins
- Custom server configuration

This is the setup that successfully worked with mods.

### Docker Compose Setup

The included `docker-compose.yml` is from the earlier Docker setup.

That setup can work for a basic vanilla L4D2 server, but it is **not recommended for MetaMod/SourceMod**.

During testing, the Docker image caused plugin loading problems with MetaMod/SourceMod because it attempted to load the wrong plugin architecture.

So:

```text
Native Linux setup = recommended for mods
Docker Compose setup = vanilla only
```

---

## Final Working Server Path

The working native Linux server was installed here:

```bash
/mnt/l4d2/l4d2-server
```

SteamCMD was kept separate here:

```bash
/mnt/l4d2/steamcmd
```

Folder layout:

```text
/mnt/l4d2/
├── steamcmd/
└── l4d2-server/
```

---

## Features Working

- Server starts successfully
- Server is joinable
- Steam connection works
- VAC secure mode works
- MetaMod loads successfully
- SourceMod loads successfully
- SourceMod plugins load successfully
- Versus mode can be configured
- Server can run in the background using `screen`

---

## Verified Working Versions

### MetaMod:Source

```text
Metamod:Source version 1.12.0-dev+1224
```

### SourceMod

```text
SourceMod Version: 1.12.0.7212
```

---

## Basic Server Start Command

From the server folder:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

---

## Recommended: Run Server in `screen`

Start a screen session:

```bash
screen -S l4d2
```

Start the server inside screen:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

Detach without stopping the server:

```text
CTRL + A
then press D
```

Reconnect later:

```bash
screen -r l4d2
```

Check running screen sessions:

```bash
screen -ls
```

Stop the server safely from the server console:

```text
quit
```

---

## Server Configuration

The main server config file is:

```bash
/mnt/l4d2/l4d2-server/left4dead2/cfg/server.cfg
```

Example `server.cfg`:

```cfg
hostname "L4D2 Versus Server"
sv_gametypes "versus"
mp_gamemode "versus"
sv_allow_lobby_connect_only "0"
sv_visiblemaxplayers "8"
sv_lan "0"
```

---

## MetaMod and SourceMod Verification

Run these commands in the server console.

Check MetaMod:

```text
meta version
meta list
```

Check SourceMod:

```text
sm version
sm plugins list
```

Expected results should show:

```text
Metamod:Source version 1.12.0-dev+1224
[META] Loaded 1 plugin.
SourceMod Version: 1.12.0.7212
[SM] Listing plugins
```

---

## SourceMod Notes

The default SourceMod `nextmap.smx` plugin may be incompatible with Left 4 Dead 2.

If it shows an error, move it to the disabled folder:

```bash
cd /mnt/l4d2/l4d2-server

mkdir -p left4dead2/addons/sourcemod/plugins/disabled
mv left4dead2/addons/sourcemod/plugins/nextmap.smx left4dead2/addons/sourcemod/plugins/disabled/
```

---

## Docker Compose Option

The included Docker Compose setup is kept for reference.

Use it only if you want a simple vanilla server without MetaMod or SourceMod.

Example Docker Compose concept:

```yaml
services:
  l4d2-server:
    image: left4devops/l4d2
    container_name: l4d2_server
    ports:
      - "27015:27015/udp"
      - "27015:27015/tcp"
    command: >
      bash -lc "cd /home/louis/l4d2 && ./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_visiblemaxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0"
```

### Docker Limitation

The Docker setup was able to run a vanilla server, but MetaMod/SourceMod caused issues.

For plugins and mods, use the native Linux setup instead.

---

## Related Files

This repository may include:

```text
README.md
docker-compose.yml
l4d2-server-command-cheat-sheet.md
l4d2-server-setup-guide.md
```

Recommended reading order:

1. `README.md`
2. `l4d2-server-setup-guide.md`
3. `l4d2-server-command-cheat-sheet.md`

---

## Security Notes

If a real Steam account was used with SteamCMD to download depots:

- Remove SteamCMD login/session files after downloading
- Use Steam Guard
- Change the Steam password afterward if desired
- Do not commit Steam credentials to GitHub

Cleanup commands used:

```bash
rm -rf ~/Steam/config
rm -rf ~/Steam/logs
rm -rf /mnt/l4d2/steamcmd/config
rm -rf /mnt/l4d2/steamcmd/logs
rm -f /mnt/l4d2/steamcmd/ssfn*
```

Do not commit any personal Steam account information.

---

## Status

Current known-good status:

```text
Native Linux L4D2 server: working
MetaMod: working
SourceMod: working
VAC: working
Docker vanilla server: worked
Docker modded server: not recommended
```
