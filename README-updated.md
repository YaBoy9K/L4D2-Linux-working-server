# L4D2 Linux Working Server

This repository documents a working **Left 4 Dead 2 Dedicated Server** setup on Linux.

The final working setup uses a **native Linux server install** with:

- Left 4 Dead 2 Dedicated Server
- MetaMod:Source
- SourceMod
- Left 4 DHooks Direct
- Custom SourceMod plugins
- Versus mode configuration
- Steam group configuration
- `screen` for keeping the server running in the background

There is also an older Docker Compose setup included, but that setup is only recommended for a **vanilla server without mods**.

---

## Important Notes

### Recommended Setup

Use the **native Linux setup** if you want:

- MetaMod
- SourceMod
- Admin menu
- SourceMod plugins
- Left 4 DHooks Direct
- Custom server configuration
- Versus mode support

This is the setup that successfully worked with mods.

### Docker Compose Setup

The included `docker-compose.yml` is from the earlier Docker setup.

That setup can work for a basic vanilla L4D2 server, but it is **not recommended for MetaMod/SourceMod**.

During testing, the Docker image caused plugin loading problems with MetaMod/SourceMod because it attempted to load the wrong plugin architecture.

```text
Native Linux setup = recommended for mods
Docker Compose setup = vanilla only
```

---

## Final Working Server Path

The working native Linux server is installed here:

```bash
/mnt/l4d2/l4d2-server
```

SteamCMD is kept separately here:

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
- Server is joinable by public IP
- Steam connection works
- VAC secure mode works
- MetaMod loads successfully
- SourceMod loads successfully
- Left 4 DHooks Direct loads successfully
- SourceMod plugins load successfully
- Versus mode works when started with the correct command
- SourceMod admin menu works after adding admin SteamID
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

### Left 4 DHooks Direct

```text
Left 4 DHooks Direct 1.166
```

---

## Basic Server Start Command

Use this command for the working Versus setup:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +mp_gamemode versus +map c8m1_apartment versus +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

Important part:

```text
+mp_gamemode versus +map c8m1_apartment versus
```

Without that, the server may start as campaign/coop instead of Versus.

---

## Recommended: Run Server in `screen`

Start a screen session:

```bash
screen -S l4d2
```

Start the server inside screen:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +mp_gamemode versus +map c8m1_apartment versus +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
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

Current working `server.cfg` example:

```cfg
hostname "L4D2 Versus Server"
sv_gametypes "versus"
mp_gamemode "versus"
sv_allow_lobby_connect_only "0"
sv_visiblemaxplayers "8"
sv_lan "0"

sv_steamgroup "103582791475626439"
sv_steamgroup_exclusive "0"
```

Note: Some team balance/shuffle cvars do not work in L4D2 multiplayer and may show as unknown commands or cheat-protected. If teams shuffle between rounds, a SourceMod team-management plugin may be needed.

---

## Steam Group / Joining Notes

The server is configured with a Steam group:

```cfg
sv_steamgroup "103582791475626439"
sv_steamgroup_exclusive "0"
```

Steam group link:

```text
https://steamcommunity.com/groups/"your steam group"
```

However, the **Steam Group Servers** list in L4D2 can be unreliable. Even with the correct group ID, the server may not always appear for group members.

Reliable join methods:

### Direct connect from L4D2 console

```text
connect PUBLIC_IP:27015
```

Example format:

```text
connect 47.xxx.xxx.xxx:27015
```

### Steam favorites

Friends can add the server through Steam:

```text
Steam → View → Game Servers → Favorites → Add Server
PUBLIC_IP:27015
```

### In-game server browser

In L4D2 console:

```text
openserverbrowser
```

Then check the Favorites tab.

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

## SourceMod Admin Setup

To use the in-game SourceMod admin menu:

```text
sm_admin
```

your SteamID must be added to:

```bash
/mnt/l4d2/l4d2-server/left4dead2/addons/sourcemod/configs/admins_simple.ini
```

Example format:

```cfg
"[U:1:STEAM3_ID_NUMBER]" "99:z"
```

After editing, reload admins from the server console:

```text
sm_reloadadmins
```

Then in-game:

```text
sm_admin
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

## Reverse Friendly-Fire Bot Setting

Reverse Friendly-Fire is controlled by:

```bash
/mnt/l4d2/l4d2-server/left4dead2/cfg/sourcemod/l4d2_reverse_ff.cfg
```

To make reverse friendly fire apply when shooting survivor bots:

```cfg
reverseff_bot "1"
reverseff_botdmgmodifier "0.0"
```

This means:

```text
Shooting survivor bots reverses damage back to the attacker.
Bots still take no real friendly-fire damage.
```

---

## Plugin List

The current SourceMod plugin list is documented here:

```text
l4d2-current-plugin-list.md
```

That file includes:

- Custom L4D2 plugins
- SourceMod default plugins
- Required gamedata files
- Required translation files
- Best-effort AlliedMods/source links

---

## Plugin Install Notes

For installing future `.smx`, `.sp`, `.txt`, `.cfg`, and translation files, see:

```text
sourcemod-plugin-install-format.md
```

Basic folder rules:

```text
.smx  -> left4dead2/addons/sourcemod/plugins/
.txt  -> left4dead2/addons/sourcemod/gamedata/
.cfg  -> left4dead2/cfg/ or left4dead2/cfg/sourcemod/
.phrases.txt -> left4dead2/addons/sourcemod/translations/
.sp   -> left4dead2/addons/sourcemod/scripting/ then compile with spcomp
.inc  -> left4dead2/addons/sourcemod/scripting/include/
```

---

## Related Files

This repository may include:

```text
README.md
docker-compose.yml
l4d2-server-setup-guide.md
l4d2-server-command-cheat-sheet.md
l4d2-file-path-cheat-sheet.md
sourcemod-plugin-install-format.md
l4d2-current-plugin-list.md
```

Recommended reading order:

1. `README.md`
2. `l4d2-server-setup-guide.md`
3. `l4d2-server-command-cheat-sheet.md`
4. `sourcemod-plugin-install-format.md`
5. `l4d2-current-plugin-list.md`

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
Left 4 DHooks Direct: working
VAC: working
Versus mode: working with corrected start command
Direct public connect: working
Steam Group Server list: unreliable
Docker vanilla server: worked
Docker modded server: not recommended
```
