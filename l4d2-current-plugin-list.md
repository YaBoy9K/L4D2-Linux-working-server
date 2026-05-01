# L4D2 SourceMod Plugin List

This file lists the SourceMod plugins currently loaded on the L4D2 Linux server.

Generated from the server console command:

```text
sm plugins list
```

Latest known loaded count:

```text
42 plugins
```

---

## Server Plugin Stack

| Component | Version / Notes | Link |
|---|---:|---|
| MetaMod:Source | 1.12.0-dev+1224 | https://www.metamodsource.net/ |
| SourceMod | 1.12.0.7212 | https://www.sourcemod.net/ |
| Left 4 DHooks Direct | 1.166 | https://forums.alliedmods.net/showthread.php?t=321696 |

---

# Custom L4D2 Plugins

These are the custom gameplay / fix plugins currently loaded.

| # | Plugin | Version | Author | Purpose / Notes | Source Link |
|---:|---|---:|---|---|---|
| 1 | [L4D & L4D2] Dissolve Infected | 1.17 | SilverShot | Dissolves infected bodies after death. Required `l4d_dissolve_infected.txt` gamedata. | https://forums.alliedmods.net/showthread.php?t=306789 |
| 2 | L4D_Ghostpounce | 1.0.3 | AtomicStryker | Infected ghost pounce / leap behavior plugin. | https://forums.alliedmods.net/showthread.php?p=891720 |
| 3 | [L4D & L4D2] God Frames Patch | 1.7 | SilverShot | Fixes/adjusts survivor god frame behavior. Required `l4d_god_frames.txt` gamedata. | https://forums.alliedmods.net/showthread.php?p=2675234 |
| 4 | [L4D1/2] Witch_allow_in_safezone | 1.1 | Lux & Harry Potter | Allows witch behavior in saferoom/safezone context. Part of Witch Fixes. | https://forums.alliedmods.net/showthread.php?t=315481 |
| 5 | Acid Swipe | 1.1 | Oshroth | Spitter/acid swipe gameplay plugin. | https://forums.alliedmods.net/showthread.php?p=1117948 |
| 6 | [L4D1/2] witch_prevent_target_loss | 1.1.1 | Lux | Prevents witch from losing target. Part of Witch Fixes. | https://forums.alliedmods.net/showthread.php?t=315481 |
| 7 | [L4D & L4D2] Left 4 DHooks Direct | 1.166 | SilverShot | Dependency required by several L4D/L4D2 plugins, including Tank Rock Bounces. | https://forums.alliedmods.net/showthread.php?t=321696 |
| 8 | [L4D1/2] Witch_Target_Patch | 1.4 | Lux | Witch target behavior patch. Part of Witch Fixes. | https://forums.alliedmods.net/showthread.php?t=315481 |
| 9 | Witch Control | 1.3 | DJ_WEST | Allows controlling/using the witch. Required `l4d2_witch_control.txt` and translations. | https://forums.alliedmods.net/showthread.php?t=125591 |
| 10 | Tank Notification | 1.1 | Weld Inclusion | Announces or notifies players about tank-related events. | https://forums.alliedmods.net/showthread.php?p=2770712 |
| 11 | [L4D2] Player Join Messages | 1.0.1 | Dirka_Dirka | Shows player join/team messages. | https://forums.alliedmods.net/showthread.php?t=132120 |
| 12 | L4D_Cloud_Damage | 2.22 | AtomicStryker | Smoker cloud damage plugin. | https://forums.alliedmods.net/showthread.php?t=96665 |
| 13 | [L4D1 & L4D2] Tank Rock Destroyer Announce | 1.1.1 | Mart | Announces which player destroyed a tank rock. Required translation file. | https://forums.alliedmods.net/showthread.php?p=2648989 |
| 14 | Jockey jump | 1.0.3 | Die Teetasse | Lets jockey jump while riding a survivor. | https://forums.alliedmods.net/showthread.php?p=2583739 |
| 15 | [L4D2] Smart Witch | 1.0.0 | Miuwiki | Changes witch target behavior so she chases another nearby survivor after killing/incapping a target. Required `witch_attack.txt`. | https://forums.alliedmods.net/showthread.php?p=2808062 |
| 16 | L4D2 Pause | 0.2.1 | pvtschlag | Pause functionality for L4D2 servers. | https://forums.alliedmods.net/showthread.php?p=997585 |
| 17 | L4D Assistance System | 1.6 | [E]c & Max Chu, SilverS & ViRaGisTe | Assistance/assist tracking system. Installed using attached `.smx`. | https://forums.alliedmods.net/showthread.php?p=1144728 |
| 18 | L4D2 Tank-on-fire Speed Booster | 1.1 | DarkNoghri && Dirka_Dirka | Boosts tank speed while on fire. | https://forums.alliedmods.net/showthread.php?t=116014 |
| 19 | [L4D2] Proper Impact Source | 0.2 | cravenge | Fixes impact source attribution. | https://forums.alliedmods.net/showthread.php?p=2770443 |
| 20 | Jockey Pounce Damage | 1.0.3 | N3wton | Adds/adjusts damage for jockey pounce. | https://forums.alliedmods.net/showthread.php?p=1129674 |
| 21 | Survivor Heal Info | 1.2 | CAPS LOCK FUCK YEAH | Shows survivor heal information. Required `healinfo.phrases.txt` translation file. | https://forums.alliedmods.net/showthread.php?p=1345541 |
| 22 | Incapped Magnum | 1.4 | Oshroth | Allows/adjusts Magnum use while incapped. | https://forums.alliedmods.net/showthread.php?p=1109372 |
| 23 | Grenade Transfer | 1.0 | DJ_WEST | Allows grenade/throwable transfer behavior. | https://forums.alliedmods.net/showthread.php?p=1128204 |
| 24 | [L4D & L4D2] Tank Rock Bounces | 1.1 | SilverShot | Allows tank rocks to bounce. Requires Left 4 DHooks Direct. | https://forums.alliedmods.net/showthread.php?p=2807009 |
| 25 | [L4D2] Witch_Double_Start_Fix | 1.0 | Lux | Fixes double witch startle behavior. Part of Witch Fixes. | https://forums.alliedmods.net/showthread.php?t=315481 |
| 26 | ~~[L4D1 & L4D2] Multi witches | 1.5.4 | Sheleu, fork by Dragokas | Allows multiple witches. | https://forums.alliedmods.net/showthread.php?p=2745084~~ |
| 27 | [L4D & L4D2] Reverse Friendly-Fire | 2.9.2 | Mystik Spiral | Reverses friendly-fire damage so the attacker takes damage instead of the victim. | https://forums.alliedmods.net/showthread.php?p=2733421 |
| 28 | L4DSwitchPlayers | 1.4 | SkyDavid / djromero | Lets admins switch/move players between teams. Appeared in an earlier loaded plugin list. | https://forums.alliedmods.net/showthread.php?p=746082 |

---

# SourceMod Default / Bundled Plugins

These come with SourceMod and provide admin commands, voting, chat/communication control, and basic server management.

| # | Plugin | Version | Author | Purpose / Notes | Link |
|---:|---|---:|---|---|---|
| 1 | Admin File Reader | 1.12.0.7212 | AlliedModders LLC | Reads admin config files. | https://www.sourcemod.net/ |
| 2 | Admin Help | 1.12.0.7212 | AlliedModders LLC | Help text for admin commands. | https://www.sourcemod.net/ |
| 3 | Admin Menu | 1.12.0.7212 | AlliedModders LLC | Provides the `sm_admin` menu. | https://wiki.alliedmods.net/Admin_Menu_%28SourceMod_Scripting%29 |
| 4 | Anti-Flood | 1.12.0.7212 | AlliedModders LLC | Chat flood protection. | https://www.sourcemod.net/ |
| 5 | Basic Ban Commands | 1.12.0.7212 | AlliedModders LLC | Basic ban commands. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 6 | Basic Chat | 1.12.0.7212 | AlliedModders LLC | Chat/admin chat tools. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 7 | Basic Comm Control | 1.12.0.7212 | AlliedModders LLC | Mute/gag/silence communication controls. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 8 | Basic Commands | 1.12.0.7212 | AlliedModders LLC | Basic admin commands like map changing, kicking, cvar changing. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 9 | Basic Info Triggers | 1.12.0.7212 | AlliedModders LLC | Info triggers such as timeleft/nextmap style commands. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 10 | Basic Votes | 1.12.0.7212 | AlliedModders LLC | Voting commands. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 11 | Client Preferences | 1.12.0.7212 | AlliedModders LLC | Client preference storage. | https://www.sourcemod.net/ |
| 12 | Fun Commands | 1.12.0.7212 | AlliedModders LLC | Fun admin commands. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 13 | Fun Votes | 1.12.0.7212 | AlliedModders LLC | Fun voting commands. | https://wiki.alliedmods.net/Base_Plugins_%28SourceMod%29 |
| 14 | Player Commands | 1.12.0.7212 | AlliedModders LLC | Player-related admin commands. | https://wiki.alliedmods.net/Admin_commands_%28sourcemod%29 |
| 15 | Reserved Slots | 1.12.0.7212 | AlliedModders LLC | Reserved slot handling. | https://www.sourcemod.net/ |
| 16 | Sound Commands | 1.12.0.7212 | AlliedModders LLC | Sound-related admin commands. | https://www.sourcemod.net/ |

---

# Installed Support Files / Notes

Some plugins required extra files beyond `.smx`:

| Plugin | Extra File(s) | Destination |
|---|---|---|
| Dissolve Infected | `l4d_dissolve_infected.txt` | `addons/sourcemod/gamedata/` |
| Witch Control | `l4d2_witch_control.txt`, `witch_control.phrases.txt` | `gamedata/`, `translations/` |
| Witch Fixes | `witch_allow_in_safezone.txt`, `witch_prevent_target_loss.txt`, `witch_target_patch.txt` | `addons/sourcemod/gamedata/` |
| Tank Rock Destroyer Announce | `l4d_tank_rock_destroyer_announce.phrases.txt` | `addons/sourcemod/translations/` |
| God Frames Patch | `l4d_god_frames.txt`, `l4d_god_frames.inc` | `gamedata/`, `scripting/include/` |
| Smart Witch | `witch_attack.txt` | `addons/sourcemod/gamedata/` |
| Survivor Heal Info | `healinfo.phrases.txt` | `addons/sourcemod/translations/` |
| Reverse Friendly-Fire | `l4d_reverse_ff.phrases.txt`, `l4d2_reverse_ff.cfg` | `translations/`, `cfg/sourcemod/` |
| Left 4 DHooks Direct | `left4dhooks.smx`, `left4dhooks.l4d2.txt`, `lux_library.txt`, include files, data cfg | `plugins/`, `gamedata/`, `scripting/include/`, `data/` |

---

# Notes

- `Nextmap` was disabled earlier because it is incompatible with L4D2.
- `L4DSwitchPlayers` appeared in an earlier plugin list, but it did not appear in the latest 42-plugin list. Keep it here only if it still exists in the plugins folder.
- Links marked `Source link not confirmed` should be updated later if the exact AlliedMods page is found.
- For forum attachments that return `403 Forbidden` with `wget`, download in a browser and copy to the server with `scp`.
