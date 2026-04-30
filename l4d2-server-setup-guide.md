# Left 4 Dead 2 Dedicated Server Setup with MetaMod and SourceMod

This guide documents the working setup for a native Linux Left 4 Dead 2 dedicated server with MetaMod and SourceMod.

This setup does **not** use Docker. It installs and runs the server directly on Linux.

---

## Final Server Layout

The server files are stored here:

```bash
/mnt/l4d2/l4d2-server
```

SteamCMD is stored separately here:

```bash
/mnt/l4d2/steamcmd
```

Recommended folder structure:

```text
/mnt/l4d2/
├── steamcmd/
└── l4d2-server/
```

---

## 1. Prepare the L4D2 Storage Folder

Set ownership so the normal Linux user can manage the server files:

```bash
sudo chown -R $USER:$USER /mnt/l4d2
```

Create separate folders for SteamCMD and the L4D2 server:

```bash
cd /mnt/l4d2
mkdir -p steamcmd l4d2-server
```

---

## 2. Install SteamCMD

```bash
cd /mnt/l4d2/steamcmd

wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd_linux.tar.gz
```

---

## 3. Download the L4D2 Dedicated Server Files

At the time this server was built, the normal anonymous SteamCMD install command returned an `Invalid platform` error for app `222860`.

The working method was to download the required depots using a Steam account that owns Left 4 Dead 2.

Start SteamCMD:

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

The depots download to:

```bash
/mnt/l4d2/steamcmd/linux32/steamapps/content/app_222860/
```

Copy the depot files into the server folder:

```bash
cp -a /mnt/l4d2/steamcmd/linux32/steamapps/content/app_222860/depot_222861/. /mnt/l4d2/l4d2-server/
cp -a /mnt/l4d2/steamcmd/linux32/steamapps/content/app_222860/depot_222863/. /mnt/l4d2/l4d2-server/
```

Verify that the server executable exists:

```bash
ls -la /mnt/l4d2/l4d2-server/srcds_run
```

Expected result:

```text
srcds_run
```

---

## 4. Fix the Steam Client Library Path

The server may look for `steamclient.so` under the user's home Steam folder. Create the expected path and symlink it to the server's local copy:

```bash
mkdir -p ~/.steam/sdk32
ln -sf /mnt/l4d2/l4d2-server/bin/steamclient.so ~/.steam/sdk32/steamclient.so
```

Verify:

```bash
ls -la ~/.steam/sdk32/steamclient.so
```

---

## 5. Fix the Executable Stack Issue

On some Linux distributions, the server may fail to load this library:

```text
libsteamvalidateuseridtickets.so
```

with an error similar to:

```text
cannot enable executable stack as shared object requires
```

Install `patchelf`:

```bash
sudo apt update
sudo apt install -y patchelf binutils
```

Clear the executable stack flag:

```bash
patchelf --clear-execstack /mnt/l4d2/l4d2-server/bin/libsteamvalidateuseridtickets.so
```

Verify with `readelf`:

```bash
readelf -l /mnt/l4d2/l4d2-server/bin/libsteamvalidateuseridtickets.so | grep -A1 GNU_STACK
```

Expected result should show `RW`, not `RWE`:

```text
GNU_STACK ... RW
```

---

## 6. Test the Base Server

Start the server:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

A successful startup should include:

```text
Connection to Steam servers successful.
VAC secure mode is activated.
```

Stop the server before installing mods:

```text
CTRL + C
```

---

## 7. Install MetaMod

This working setup used MetaMod 1.12 build 1224.

```bash
cd /mnt/l4d2/l4d2-server

wget https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1224/mmsource-1.12.0-git1224-linux.tar.gz
tar -xzf mmsource-1.12.0-git1224-linux.tar.gz -C left4dead2
```

Remove the 64-bit loader file/folder to avoid the server trying to load the wrong architecture:

```bash
rm -f left4dead2/addons/metamod_x64.vdf
rm -rf left4dead2/addons/metamod/bin/linux64
```

Create the MetaMod loader file:

```bash
cat > left4dead2/addons/metamod.vdf <<EOF
"Plugin"
{
    "file" "addons/metamod/bin/server"
}
EOF
```

Start the server again:

```bash
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

In the server console, check MetaMod:

```text
meta version
meta list
```

Expected result:

```text
Metamod:Source version 1.12.0-dev+1224
No plugins loaded.
```

Stop the server before installing SourceMod:

```text
quit
```

---

## 8. Install SourceMod

This working setup used SourceMod 1.12 build 7212.

```bash
cd /mnt/l4d2/l4d2-server

wget https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7212-linux.tar.gz
tar -xzf sourcemod-1.12.0-git7212-linux.tar.gz -C left4dead2
```

Start the server:

```bash
./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

Check SourceMod in the server console:

```text
sm version
sm plugins list
```

Expected result:

```text
SourceMod Version: 1.12.0.7212
[SM] Listing plugins
```

---

## 9. Disable the Incompatible Nextmap Plugin

The default SourceMod `nextmap.smx` plugin may show:

```text
Nextmap is incompatible with this game.
```

Disable it:

```bash
cd /mnt/l4d2/l4d2-server

mkdir -p left4dead2/addons/sourcemod/plugins/disabled
mv left4dead2/addons/sourcemod/plugins/nextmap.smx left4dead2/addons/sourcemod/plugins/disabled/
```

---

## 10. Create `server.cfg`

Create the config file:

```bash
nano /mnt/l4d2/l4d2-server/left4dead2/cfg/server.cfg
```

Example configuration:

```cfg
hostname "L4D2 Versus Server"
sv_gametypes "versus"
mp_gamemode "versus"
sv_allow_lobby_connect_only "0"
sv_visiblemaxplayers "8"
sv_lan "0"
```

Save and exit.

---

## 11. Run the Server in `screen`

Install screen if needed:

```bash
sudo apt install -y screen
```

Start a screen session:

```bash
screen -S l4d2
```

Start the server inside the screen session:

```bash
cd /mnt/l4d2/l4d2-server

./srcds_run -game left4dead2 -console -usercon -ip 0.0.0.0 -port 27015 +map c8m1_apartment +maxplayers 8 +sv_gametypes versus +sv_allow_lobby_connect_only 0
```

Detach from the screen session without stopping the server:

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

## 12. Steam Account Safety Cleanup

If a real Steam account was used to download the depots, remove SteamCMD session/config files afterward:

```bash
rm -rf ~/Steam/config
rm -rf /mnt/l4d2/steamcmd/config
rm -rf /mnt/l4d2/steamcmd/logs
```

Recommended safety steps:

- Use Steam Guard / Steam Mobile Authenticator.
- Use a temporary password during setup if desired.
- Change the Steam password after setup.
- Do not leave SteamCMD logged in on the server.

---

## 13. Final Verification Commands

Run these in the server console:

```text
meta version
meta list
sm version
sm plugins list
```

Working setup should show:

```text
Metamod:Source version 1.12.0-dev+1224
[META] Loaded 1 plugin.
SourceMod Version: 1.12.0.7212
[SM] Listing plugins
Connection to Steam servers successful.
VAC secure mode is activated.
```

---

## Notes

- This guide intentionally avoids Docker because the modded setup worked correctly as a native Linux server.
- The server is configured for Versus mode.
- The server path used is `/mnt/l4d2/l4d2-server`.
- The SteamCMD path used is `/mnt/l4d2/steamcmd`.
- No personal Steam account information should be committed to GitHub.
