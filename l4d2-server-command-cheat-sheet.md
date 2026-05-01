# L4D2 Server Command Cheat Sheet

This is a quick reference for managing a native Linux Left 4 Dead 2 dedicated server with MetaMod and SourceMod installed.

Server path used in this guide:

```bash
/mnt/l4d2/l4d2-server
```

---

## 1. Go to the server folder

```bash
cd /mnt/l4d2/l4d2-server
```

---

## 2. Start the server normally

Use this if you are okay with the terminal staying attached to the server console.

```bash
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +mp_gamemode versus +map c8m1_apartment versus +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

---

## 3. Start the server in `screen` — recommended

Use this if you want the server to keep running after you leave the terminal.

```bash
screen -S l4d2
```

Then inside the screen session:

```bash
cd /mnt/l4d2/l4d2-server
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

---

## 4. Leave terminal without closing the server

While inside the running `screen` session, press:

```text
CTRL + A
then press D
```

This detaches from the server console and leaves the server running.

---

## 5. Reconnect to the server console later

```bash
screen -r l4d2
```

---

## 6. Check if the screen session/server is running

```bash
screen -ls
```

Example output:

```text
12345.l4d2    (Detached)
```

---

## 7. Stop/close the server safely

Reconnect first:

```bash
screen -r l4d2
```

Then in the server console, type:

```text
quit
```

Or press:

```text
CTRL + C
```

---

## 8. Force-kill the screen session if needed

Only use this if the server is stuck.

```bash
screen -S l4d2 -X quit
```

---

## 9. Check if port 27015 is being used

```bash
sudo ss -tulpn | grep 27015
```

---

## 10. Check running L4D2 server processes

```bash
ps aux | grep srcds
```

---

# MetaMod / SourceMod Checks

## 11. Check MetaMod version

Run this in the server console:

```text
meta version
```

---

## 12. Check loaded MetaMod plugins

Run this in the server console:

```text
meta list
```

---

## 13. Check SourceMod version

Run this in the server console:

```text
sm version
```

---

## 14. Check SourceMod plugins

Run this in the server console:

```text
sm plugins list
```

---

## 15. Reload SourceMod plugins

Run this in the server console:

```text
sm plugins refresh
```

---

# Config Files

## 16. Edit `server.cfg`

```bash
nano /mnt/l4d2/l4d2-server/left4dead2/cfg/server.cfg
```

Example basic `server.cfg`:

```cfg
hostname "YaBoy9K L4D2 Versus Server"
sv_gametypes "versus"
mp_gamemode "versus"
sv_allow_lobby_connect_only "0"
sv_visiblemaxplayers "8"
sv_lan "0"
```

---

## 17. Edit SourceMod admin file

```bash
nano /mnt/l4d2/l4d2-server/left4dead2/addons/sourcemod/configs/admins_simple.ini
```

---

## 18. View SourceMod plugin config files

```bash
ls /mnt/l4d2/l4d2-server/left4dead2/cfg/sourcemod
```

Edit a plugin config file:

```bash
nano /mnt/l4d2/l4d2-server/left4dead2/cfg/sourcemod/pluginname.cfg
```

---

# Restart Workflow

## 19. Restart the server cleanly

Reconnect to the server console:

```bash
screen -r l4d2
```

Then type:

```text
quit
```

Start it again:

```bash
screen -S l4d2
cd /mnt/l4d2/l4d2-server
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

Detach:

```text
CTRL + A
then D
```

---

# Steam / Update Commands

## 20. Update L4D2 server files

Only do this when the server is stopped.

```bash
cd /mnt/l4d2/steamcmd

./steamcmd.sh +login YOUR_STEAM_USERNAME +force_install_dir /mnt/l4d2/l4d2-server +app_update 222860 validate +quit
```

Note: `app_update 222860` may return `Invalid platform`. The working method used for this setup was the depot method below.

---

## 21. Update using the depot method

Use this only if you need to redownload or refresh the server files.

```bash
cd /mnt/l4d2/steamcmd
./steamcmd.sh
```

Inside SteamCMD:

```text
login YOUR_STEAM_USERNAME
download_depot 222860 222861 4827977561765481436
download_depot 222860 222863 2405357637318523777
quit
```

Then copy the depot files into the server folder:

```bash
cp -a /mnt/l4d2/steamcmd/linux32/steamapps/content/app_222860/depot_222861/. /mnt/l4d2/l4d2-server/
cp -a /mnt/l4d2/steamcmd/linux32/steamapps/content/app_222860/depot_222863/. /mnt/l4d2/l4d2-server/
```

---

# Steam Account Safety Cleanup

## 22. Remove SteamCMD login/session files after using your Steam account

```bash
rm -rf ~/Steam/config
rm -rf /mnt/l4d2/steamcmd/config
rm -rf /mnt/l4d2/steamcmd/logs
```

Afterward, change your Steam password again if you used a temporary password.

---

# Recommended Normal Use

Most days, you only need these commands.

## Start server

```bash
screen -S l4d2
cd /mnt/l4d2/l4d2-server
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

## Detach from server

```text
CTRL + A
then D
```

## Reconnect later

```bash
screen -r l4d2
```

## Check if it is running

```bash
screen -ls
```

## Stop server

```bash
screen -r l4d2
```

Then in the server console:

```text
quit
```
