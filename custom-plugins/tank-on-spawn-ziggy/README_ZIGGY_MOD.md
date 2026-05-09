[README_ZIGGY_MOD.md](https://github.com/user-attachments/files/27545372/README_ZIGGY_MOD.md)
# [L4D1 & L4D2] Tank on Spawn - Ziggy Modified Source

## What changed
- Adds l4d_tank_on_spawn_force_every_map "1"
  Starts the saferoom-leave Tank timer on every chapter instead of only first maps.

- Adds l4d_tank_on_spawn_one_tank_alive "1"
  If a second Tank appears while one Tank is already alive, the new one is kicked.
  The forced spawn timer also refuses to spawn if a Tank is already alive.

- Adds l4d_tank_on_spawn_versus_only "1"
  Spawn/control logic only runs when mp_gamemode contains "versus".

- Changes saferoom forced spawn logic:
  After survivors leave the saferoom, the plugin waits between delay_min and delay_max.
  If the director already spawned a Tank this chapter, the plugin does nothing.
  If a Tank is alive when the timer fires, the plugin does nothing.
  If no Tank has appeared and no Tank is alive, the plugin spawns one Tank.

- Changes safer defaults:
  l4d_tank_on_spawn_enable_duplicate default: 0
  l4d_tank_on_spawn_count default: 1
  l4d_tank_on_spawn_countlimit default: 1
  l4d_tank_on_spawn_control_hp default: 0

## Install
1. Compile addons/sourcemod/scripting/l4d_TankOnSpawn.sp with SourceMod's spcomp.
2. Put the compiled l4d_TankOnSpawn.smx in addons/sourcemod/plugins/.
3. Put translations/l4d_TankOnSpawn.phrases.txt in addons/sourcemod/translations/.
4. Put gamedata/tankonspawn.txt in addons/sourcemod/gamedata/ if you are not using Left4DHooks.
5. Put cfg/sourcemod/l4d_tank_on_spawn.cfg in your server cfg/sourcemod folder.
6. Restart the server or change map.

## Important
- Do not use the old .smx from the original zip for this modified behavior. It is still the unmodified compiled plugin.
- If SourceMod already generated an old cfg/sourcemod/l4d_tank_on_spawn.cfg, replace it or add the new ConVars manually.
