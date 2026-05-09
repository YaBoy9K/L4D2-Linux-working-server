#define PLUGIN_VERSION		"1.30-ziggy1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <geoip>
#undef REQUIRE_PLUGIN
#tryinclude <left4dhooks>

#define DEBUG 0
#define TEAM_SURVIVOR 2
#define MAX_SPECIALS 64 - 16
#define MAX_PLAYERS_CVAR 16
#define CVAR_FLAGS			FCVAR_NOTIFY

enum INFO_LEVEL
{
	INFO_LEVEL_CONSOLE = 1,
	INFO_LEVEL_SERVER = 2
}

ConVar g_ConVarEnable, g_ConVarChanceFM, g_ConVarMinDelay, g_ConVarMaxDelay, g_ConVarSpawnInterval, g_ConVarCount, g_ConVarCountLimit, g_ConVarCountMode, g_ConVarControlHP, g_ConVarHP, g_ConVarVoteAccess, g_hCvarAnnounceDelay;
ConVar g_hCvarTimeout, g_hCvarLog, g_hCvarTanksOnPlayers[MAX_PLAYERS_CVAR+1], g_hCvarHpMultiplier[MAX_PLAYERS_CVAR+1], g_hCvarHpFactorEasy, g_hCvarHpFactorNormal, g_hCvarHpFactorHard, g_hCvarHpFactorExpert;
ConVar g_hCvarAddTanksOnEasy, g_hCvarAddTanksOnNormal, g_hCvarAddTanksOnHard, g_hCvarAddTanksOnExpert, g_hCvarIngoneRush, g_ConVarDifficulty, g_ConVarMaxSpecials, g_ConVarZTankHealth, g_hCvarAddTanksOnFirstMap;
ConVar g_hCvarVoteDelay, g_hCvarVoteMaxCount, g_hCvarAddFinaleTanks, g_ConVarAnnouncement, g_ConVarMaxSpecials2, g_hCvarCreateTankAccessFlag, g_ConVarEnableDuplicate;
ConVar g_hCvarDirectorWavesInterval_Fin, g_hCvarDirectorWavesInterval_Min, g_hCvarDirectorWavesInterval_Max, g_hCvarMapStartRelax, g_hCvarInfoLevel;
ConVar g_hCvarForceEveryMap, g_hCvarOneTankAlive, g_hCvarVersusOnly, g_hCvarGameMode;
// ConVar g_ConVarFailSpawnMode, g_ConVarFailSpawnDistanceMin;

char g_sLog[PLATFORM_MAX_PATH], g_sMap[64];

bool g_bRoundStarted, g_bFirstMap, g_bApplyMenuCount, g_bApplyMenuHealth, g_bSkipCvarChange, g_bVeto, g_bVotepass, g_bVoteInProgress, g_bVoteDisplayed, g_bTankBeenSpawn, g_bDuplicateTank = true;
bool g_bLeft4Dead2, g_bLateload, g_bLeft4DHooks, g_bEasy, g_bNormal, g_bHard, g_bExpert, g_bFinale, g_bVehicleLeaving, g_bDedicated, g_bTankSpawnedThisRound;

int g_iVoteType, g_iOffsetLeftSafeArea, g_iEntPlayerResource, g_iMaxSpecialsInit, g_iMaxSpecialsInit2, g_iTanksKilled, g_iTanksRequired, g_iValue, g_iVotesDone[MAXPLAYERS+1], g_iDirectorWavesInterval, g_iLastTimeDeadTank;

Handle g_hTimerSafeArea, g_hTimerSpawnTanksDelay, g_hTimerSpawnTanks, g_hTimerFirstTank;

/* ====================================================================================================
					PLUGIN INFO / START / END
   ====================================================================================================*/

public Plugin myinfo =
{
	name = "[L4D] Tank on Spawn",
	author = "Dragokas",
	description = "Guarantees a Tank each chapter without blocking normal director Tanks; one Tank alive limit",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 ) {
		g_bLeft4Dead2 = true;
	}
	else if( test != Engine_Left4Dead ) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	g_bDedicated = IsDedicatedServer();
	MarkNativeAsOptional("L4D_IsFirstMapInScenario");
	MarkNativeAsOptional("L4D_IsMissionFinalMap");
	MarkNativeAsOptional("L4D_OnGetScriptValueInt");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_TankOnSpawn.phrases");
	
	CreateConVar("l4d_tank_on_spawn_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	g_ConVarEnable = 				CreateConVar("l4d_tank_on_spawn_enabled", 			"1", 		"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarEnableDuplicate = 		CreateConVar("l4d_tank_on_spawn_enable_duplicate", 	"0", 		"Enable tanks duplication (1 - On / 0 - Off, in this case plugin will only control tank's hp)", CVAR_FLAGS);
	g_ConVarChanceFM = 				CreateConVar("l4d_tank_on_spawn_fm_chance", 		"100", 		"Chance the tank is appear on first map (1 to 100), 0 - to disable.", CVAR_FLAGS);
	g_ConVarMinDelay = 				CreateConVar("l4d_tank_on_spawn_delay_min", 		"30.0", 	"Minimum delay tank spawn on first map after survivors left safe area", CVAR_FLAGS);
	g_ConVarMaxDelay = 				CreateConVar("l4d_tank_on_spawn_delay_max", 		"80.0", 	"Maximum delay tank spawn on first map after survivors left safe area", CVAR_FLAGS);
	g_ConVarSpawnInterval = 		CreateConVar("l4d_tank_on_spawn_interval", 			"5.0", 		"Number of seconds between each new tank spawn", CVAR_FLAGS);
	g_ConVarCountMode = 			CreateConVar("l4d_tank_on_spawn_countmode", 		"1", 		"1 - set tank count based on convar + menu / 2 - set tank count based on number of players (auto-balancer)", CVAR_FLAGS);
	g_ConVarCount = 				CreateConVar("l4d_tank_on_spawn_count", 			"1", 		"Number of tanks to spawn (for mode = 1)", CVAR_FLAGS);
	g_ConVarCountLimit = 			CreateConVar("l4d_tank_on_spawn_countlimit", 		"1", 		"Maximum number of tanks allowed simultaneously exist on the map (other will be moved in spawn queue)", CVAR_FLAGS);
	g_ConVarControlHP = 			CreateConVar("l4d_tank_on_spawn_control_hp", 		"0", 		"Do we need to control tank HP ? ( 0 - No / 1 - Fixed hp / 2 - Auto-balancer hp, based on players count)", CVAR_FLAGS);
	g_ConVarHP = 					CreateConVar("l4d_tank_on_spawn_hp", 				"10000", 	"HP of tank to set", CVAR_FLAGS);
	g_ConVarVoteAccess =			CreateConVar("l4d_tank_on_spawn_voteaccess", 		"k", 		"Flag(s) required to start the vote (leave empty to allow vote access for everybody)", CVAR_FLAGS);
	g_hCvarAnnounceDelay = 			CreateConVar("l4d_tank_on_spawn_announcedelay",		"2.0",		"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarTimeout = 				CreateConVar("l4d_tank_on_spawn_vote_timeout",		"10",		"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarVoteDelay = 				CreateConVar("l4d_tank_on_spawn_vote_delay",		"60",		"Minimum delay (in sec.) allowed between identical vote types", CVAR_FLAGS );
	g_hCvarVoteMaxCount = 			CreateConVar("l4d_tank_on_spawn_vote_maxcount",		"4",		"Maximum count of votes allowed to do for each player per 1 round", CVAR_FLAGS );
	g_hCvarLog = 					CreateConVar("l4d_tank_on_spawn_log",				"1",		"Use logging? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[1] = 		CreateConVar("l4d_tank_on_spawn_players_1",			"1",		"How many tanks should be in wave when count of players is: 1", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[2] = 		CreateConVar("l4d_tank_on_spawn_players_2",			"1",		"How many tanks should be in wave when count of players is: 2", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[3] = 		CreateConVar("l4d_tank_on_spawn_players_3",			"2",		"How many tanks should be in wave when count of players is: 3", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[4] = 		CreateConVar("l4d_tank_on_spawn_players_4",			"2",		"How many tanks should be in wave when count of players is: 4", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[5] = 		CreateConVar("l4d_tank_on_spawn_players_5",			"3",		"How many tanks should be in wave when count of players is: 5", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[6] = 		CreateConVar("l4d_tank_on_spawn_players_6",			"3",		"How many tanks should be in wave when count of players is: 6", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[7] = 		CreateConVar("l4d_tank_on_spawn_players_7",			"3",		"How many tanks should be in wave when count of players is: 7", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[8] = 		CreateConVar("l4d_tank_on_spawn_players_8",			"3",		"How many tanks should be in wave when count of players is: 8", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[9] = 		CreateConVar("l4d_tank_on_spawn_players_9",			"4",		"How many tanks should be in wave when count of players is: 9", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[10] = 	CreateConVar("l4d_tank_on_spawn_players_10",		"4",		"How many tanks should be in wave when count of players is: 10", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[11] = 	CreateConVar("l4d_tank_on_spawn_players_11",		"4",		"How many tanks should be in wave when count of players is: 11", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[12] = 	CreateConVar("l4d_tank_on_spawn_players_12",		"4",		"How many tanks should be in wave when count of players is: 12", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[13] = 	CreateConVar("l4d_tank_on_spawn_players_13",		"4",		"How many tanks should be in wave when count of players is: 13", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[14] = 	CreateConVar("l4d_tank_on_spawn_players_14",		"4",		"How many tanks should be in wave when count of players is: 14", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[15] = 	CreateConVar("l4d_tank_on_spawn_players_15",		"4",		"How many tanks should be in wave when count of players is: 15", CVAR_FLAGS );
	g_hCvarTanksOnPlayers[16] = 	CreateConVar("l4d_tank_on_spawn_players_16",		"4",		"How many tanks should be in wave when count of players is: 16 and more", CVAR_FLAGS );
	g_hCvarHpMultiplier[1] =		CreateConVar("l4d_tank_on_spawn_hpfactor_1",		"1.0",		"Multiplier of HP when count of players is: 1", CVAR_FLAGS );
	g_hCvarHpMultiplier[2] =		CreateConVar("l4d_tank_on_spawn_hpfactor_2",		"1.0",		"Multiplier of HP when count of players is: 2", CVAR_FLAGS );
	g_hCvarHpMultiplier[3] =		CreateConVar("l4d_tank_on_spawn_hpfactor_3",		"1.5",		"Multiplier of HP when count of players is: 3", CVAR_FLAGS );
	g_hCvarHpMultiplier[4] =		CreateConVar("l4d_tank_on_spawn_hpfactor_4",		"1.5",		"Multiplier of HP when count of players is: 4", CVAR_FLAGS );
	g_hCvarHpMultiplier[5] =		CreateConVar("l4d_tank_on_spawn_hpfactor_5",		"2.0",		"Multiplier of HP when count of players is: 5", CVAR_FLAGS );
	g_hCvarHpMultiplier[6] =		CreateConVar("l4d_tank_on_spawn_hpfactor_6",		"2.2",		"Multiplier of HP when count of players is: 6", CVAR_FLAGS );
	g_hCvarHpMultiplier[7] =		CreateConVar("l4d_tank_on_spawn_hpfactor_7",		"2.5",		"Multiplier of HP when count of players is: 7", CVAR_FLAGS );
	g_hCvarHpMultiplier[8] =		CreateConVar("l4d_tank_on_spawn_hpfactor_8",		"3.0",		"Multiplier of HP when count of players is: 8", CVAR_FLAGS );
	g_hCvarHpMultiplier[9] =		CreateConVar("l4d_tank_on_spawn_hpfactor_9",		"3.5",		"Multiplier of HP when count of players is: 9", CVAR_FLAGS );
	g_hCvarHpMultiplier[10] =		CreateConVar("l4d_tank_on_spawn_hpfactor_10",		"4.0",		"Multiplier of HP when count of players is: 10", CVAR_FLAGS );
	g_hCvarHpMultiplier[11] =		CreateConVar("l4d_tank_on_spawn_hpfactor_11",		"4.5",		"Multiplier of HP when count of players is: 11", CVAR_FLAGS );
	g_hCvarHpMultiplier[12] =		CreateConVar("l4d_tank_on_spawn_hpfactor_12",		"5.0",		"Multiplier of HP when count of players is: 12", CVAR_FLAGS );
	g_hCvarHpMultiplier[13] =		CreateConVar("l4d_tank_on_spawn_hpfactor_13",		"5.0",		"Multiplier of HP when count of players is: 13", CVAR_FLAGS );
	g_hCvarHpMultiplier[14] =		CreateConVar("l4d_tank_on_spawn_hpfactor_14",		"5.0",		"Multiplier of HP when count of players is: 14", CVAR_FLAGS );
	g_hCvarHpMultiplier[15] =		CreateConVar("l4d_tank_on_spawn_hpfactor_15",		"5.0",		"Multiplier of HP when count of players is: 15", CVAR_FLAGS );
	g_hCvarHpMultiplier[16] =		CreateConVar("l4d_tank_on_spawn_hpfactor_16",		"5.0",		"Multiplier of HP when count of players is: 16 and more", CVAR_FLAGS );
	g_hCvarHpFactorEasy =			CreateConVar("l4d_tank_on_spawn_hpfactor_easy",		"0.3",		"Additional multiplier of HP on difficulty: easy", CVAR_FLAGS );
	g_hCvarHpFactorNormal =			CreateConVar("l4d_tank_on_spawn_hpfactor_normal",	"0.5",		"Additional multiplier of HP on difficulty: normal", CVAR_FLAGS );
	g_hCvarHpFactorHard =			CreateConVar("l4d_tank_on_spawn_hpfactor_hard",		"1.0",		"Additional multiplier of HP on difficulty: hard", CVAR_FLAGS );
	g_hCvarHpFactorExpert =			CreateConVar("l4d_tank_on_spawn_hpfactor_expert",	"2.5",		"Additional multiplier of HP on difficulty: impossible", CVAR_FLAGS );
	g_hCvarAddTanksOnEasy =			CreateConVar("l4d_tank_on_spawn_add_tanks_easy",	"0",		"How many tanks should be added on difficulty: easy (negative values are allowed)", CVAR_FLAGS );
	g_hCvarAddTanksOnNormal =		CreateConVar("l4d_tank_on_spawn_add_tanks_normal",	"0",		"How many tanks should be added on difficulty: normal (negative values are allowed)", CVAR_FLAGS );
	g_hCvarAddTanksOnHard =			CreateConVar("l4d_tank_on_spawn_add_tanks_hard",	"0",		"How many tanks should be added on difficulty: hard (negative values are allowed)", CVAR_FLAGS );
	g_hCvarAddTanksOnExpert =		CreateConVar("l4d_tank_on_spawn_add_tanks_expert",	"0",		"How many tanks should be added on difficulty: impossible (negative values are allowed)", CVAR_FLAGS );
	g_hCvarAddTanksOnFirstMap =		CreateConVar("l4d_tank_on_spawn_add_tanks_firstmap","0",		"How many tanks should be added on first map (negative values are allowed)", CVAR_FLAGS );
	g_hCvarAddFinaleTanks =			CreateConVar("l4d_tank_on_spawn_add_finale_tanks",	"0",		"How many tanks should be added on finale (negative values are allowed)", CVAR_FLAGS );
	g_hCvarIngoneRush =				CreateConVar("l4d_tank_on_spawn_ignore_rush",		"1",		"Do not double tanks if somebody rushed when previous tank wave is not yet killed? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_ConVarAnnouncement =			CreateConVar("l4d_tank_on_spawn_announcement",		"1",		"Make announcement in chat when the tank is about to appear? (1 - Yes / 0 - No)", CVAR_FLAGS );
	//g_ConVarFailSpawnMode =			CreateConVar("l4d_tank_on_spawn_fail_spawn_mode",	"3",		"When game failed to spawn tank, what to do? (0 - Nothing, spawn with next delay; 1 - Try to spawn next to every player; 2 - manually and guarantee spawn next to player). You can combine flags.", CVAR_FLAGS );
	//g_ConVarFailSpawnDistanceMin =	CreateConVar("l4d_tank_on_spawn_fail_spawn_mindist","50",		"Minimum distance to player allowed to spawn tank (for fail_spawn_mode == 2)", CVAR_FLAGS);
	g_hCvarCreateTankAccessFlag = 	CreateConVar("l4d_tank_on_spawn_create_tank_flag",	"s",		"Admin flag required to spawn a tank via the menu", CVAR_FLAGS );
	g_hCvarDirectorWavesInterval_Fin = 	CreateConVar("l4d_tank_on_spawn_director_waves_interval_fin",	"0",	"(for finale) Minimum time (in sec.) required before allowing director to spawn a new tank wave after the last tank died", CVAR_FLAGS );
	g_hCvarDirectorWavesInterval_Min = 	CreateConVar("l4d_tank_on_spawn_director_waves_interval_min",	"0",	"(before finale) Minimum random start time (in sec.) required before allowing director to spawn a new tank wave after the last tank died", CVAR_FLAGS );
	g_hCvarDirectorWavesInterval_Max = 	CreateConVar("l4d_tank_on_spawn_director_waves_interval_max",	"0",	"(before finale) Minimum random end time (in sec.) required before allowing director to spawn a new tank wave after the last tank died", CVAR_FLAGS );
	g_hCvarMapStartRelax = 				CreateConVar("l4d_tank_on_spawn_mapstart_relax_time",			"0",	"Prevent director from spawning tanks within this number of seconds after map started", CVAR_FLAGS );
	g_hCvarInfoLevel = 				CreateConVar("l4d_tank_on_spawn_info_level",		"3",	"Duplicate service (vote) information? 0 - No, 1 - In console, 2 - In server. (Can be combined)", CVAR_FLAGS );
	g_hCvarForceEveryMap = 			CreateConVar("l4d_tank_on_spawn_force_every_map", "1", "Guarantee a Tank after survivors leave the saferoom on every chapter/map (1 - On / 0 - Off).", CVAR_FLAGS );
	g_hCvarOneTankAlive = 			CreateConVar("l4d_tank_on_spawn_one_tank_alive", "1", "Prevent more than one Tank from being alive at the same time (1 - On / 0 - Off).", CVAR_FLAGS );
	g_hCvarVersusOnly = 				CreateConVar("l4d_tank_on_spawn_versus_only", "1", "Only run Tank spawn/control logic in Versus or Team Versus (1 - On / 0 - Off).", CVAR_FLAGS );
	
	g_ConVarMaxSpecials = FindConVar("z_max_player_zombies");
	g_hCvarGameMode = FindConVar("mp_gamemode");
	g_ConVarZTankHealth = FindConVar("z_tank_health");
	g_ConVarDifficulty = FindConVar("z_difficulty");
	
	if( g_bLeft4Dead2 )
	{
		g_ConVarMaxSpecials2 = FindConVar("survival_max_specials");
	}
	
	AutoExecConfig(true, "l4d_tank_on_spawn");
	
	g_ConVarEnable.AddChangeHook(ConVarChanged);
	g_ConVarDifficulty.AddChangeHook(ConVarChanged);
	
	RegConsoleCmd("sm_tank",		Command_MenuTankSpawn, 		"Show tank spawn menu");
	RegConsoleCmd("sm_tanks",		Command_MenuTankSpawn, 		"-||-");
	
	RegAdminCmd("sm_veto", 			Command_Veto, 		ADMFLAG_ROOT, 	"Allow admin to veto current vote.");
	RegAdminCmd("sm_votepass", 		Command_Votepass, 	ADMFLAG_ROOT, 	"Allow admin to bypass current vote.");
	
	GetCvars();
	
	g_iOffsetLeftSafeArea = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
	
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_tanks.log");
	
	if( g_bLateload )
		g_bRoundStarted = true;
}

public void OnConfigsExecuted()
{
	PreserveCvar(g_ConVarCount, false);
	PreserveCvar(g_ConVarHP, false);
}

public void OnAllPluginsLoaded()
{
	g_iMaxSpecialsInit = g_ConVarMaxSpecials.IntValue;
	g_ConVarMaxSpecials.AddChangeHook (ConVarChanged);
	
	if( g_bLeft4Dead2 )
	{
		g_iMaxSpecialsInit2 = g_ConVarMaxSpecials2.IntValue;
		g_ConVarMaxSpecials2.AddChangeHook (ConVarChanged);
	}
	
	g_bLeft4DHooks = LibraryExists("left4dhooks");
	
	if( g_bLeft4Dead2 && !g_bLeft4DHooks )
	{
		GameData hGameData = new GameData("tankonspawn");
		if( hGameData == null )
			SetFailState("Failed to load \"%s.txt\" gamedata.", "tankonspawn");
	
		Handle hDetour = DHookCreateFromConf(hGameData, "GetScriptValueInt");
		
		if( !DHookEnableDetour(hDetour, false, GetScriptValueInt) )
			LogError("Failed to detour \"%s\".", "GetScriptValueInt");
			
		delete hGameData;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLeft4DHooks = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLeft4DHooks = false;
}

bool HasCreateTankAccess(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if (iUserFlag & ADMFLAG_ROOT != 0) return true;
	
	char sReq[32];
	g_hCvarCreateTankAccessFlag.GetString(sReq, sizeof(sReq));
	if (strlen(sReq) == 0) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

bool HasVoteAccess(int client)
{
	static char sFlags[16];
	int iUserFlags = GetUserFlagBits(client);
	g_ConVarVoteAccess.GetString(sFlags, sizeof(sFlags));
	int iFlags = ReadFlagString(sFlags);
	if( iFlags == 0 || iUserFlags & iFlags || iUserFlags & ADMFLAG_ROOT )
		return true;
	return false;
}

void PreserveCvar(ConVar cv, bool bDoSave)
{
	static StringMap hMapCvar;
	static char name[100], value[16];
	if( !hMapCvar )
		hMapCvar = new StringMap();
	
	cv.GetName(name, sizeof(name));
	cv.GetString(value, sizeof(value));
	
	if( bDoSave ) {
		hMapCvar.SetString(name, value, true);
	}
	else {
		if( hMapCvar.GetString(name, value, sizeof(value)) )
		{
			FindConVar(name).SetString(value, false, false);
		}
	}
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	if( !g_bSkipCvarChange )
	{
		g_iMaxSpecialsInit = g_ConVarMaxSpecials.IntValue;
		
		if( g_bLeft4Dead2 )
		{
			g_iMaxSpecialsInit2 = g_ConVarMaxSpecials2.IntValue;
		}
	}
	
	static char sDif[32];
	g_bEasy = false;
	g_bNormal = false;
	g_bHard = false;
	g_bExpert = false;
	
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	if( strcmp(sDif, "Easy") == 0 ) {
		g_bEasy = true;
	}
	else if( strcmp(sDif, "Normal", false) == 0) {
		g_bNormal = true;
	}
	else if( strcmp(sDif, "Hard", false) == 0 ) {
		g_bHard = true;
	}
	else if( strcmp(sDif, "Impossible", false) == 0) {
		g_bExpert = true;
	}
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_ConVarEnable.BoolValue ) {
		if( !bHooked ) {
			HookEvent("round_start", 			Event_RoundStart, 		EventHookMode_PostNoCopy);
			HookEvent("tank_spawn",				Event_TankSpawn);
			HookEvent("tank_killed",			Event_TankKilled,		EventHookMode_PostNoCopy);
			HookEvent("round_end", 				Event_RoundEnd, 		EventHookMode_PostNoCopy);
			HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
			HookEvent("finale_vehicle_leaving", Event_VehicleLeaving, 	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("round_start", 			Event_RoundStart, 		EventHookMode_PostNoCopy);
			UnhookEvent("tank_spawn",			Event_TankSpawn);
			UnhookEvent("tank_killed",			Event_TankKilled,		EventHookMode_PostNoCopy);
			UnhookEvent("round_end", 			Event_RoundEnd, 		EventHookMode_PostNoCopy);
			UnhookEvent("player_disconnect",	Event_PlayerDisconnect, EventHookMode_Pre);
			UnhookEvent("finale_vehicle_leaving", Event_VehicleLeaving, EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

void SetMaxInfectedBounds(bool bAtMax = true)
{
	if( bAtMax ) {
		g_bSkipCvarChange = true;
		g_ConVarMaxSpecials.SetInt(MAX_SPECIALS);
		if( g_bLeft4Dead2 )
		{
			g_ConVarMaxSpecials2.SetInt(MAX_SPECIALS);
		}
		g_bSkipCvarChange = false;
	}
	else {
		g_ConVarMaxSpecials.SetInt(g_iMaxSpecialsInit);
		if( g_bLeft4Dead2 )
		{
			g_ConVarMaxSpecials2.SetInt(g_iMaxSpecialsInit2);
		}
	}
}

/* ===================================================================================
								C O M M A N D S
====================================================================================== */

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		client = iGetListenServerHost(client, g_bDedicated);
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		client = iGetListenServerHost(client, g_bDedicated);
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public Action Command_MenuTankSpawn(int client, int args)
{
	client = iGetListenServerHost(client, g_bDedicated);
	vMenuTankSpawn(client);
	return Plugin_Handled;
}

/* ===================================================================================
									M E N U
====================================================================================== */

void vMenuTankSpawn(int client)
{
	static char s[128];
	int health;
	if( g_ConVarCountMode.IntValue == 1 || g_bApplyMenuHealth ) {
		health = g_ConVarHP.IntValue;
	}
	else {
		health = g_ConVarZTankHealth.IntValue; // * Tank multiplier
	}
	Menu menu = new Menu(MenuHandler_MenuMain, MENU_ACTIONS_DEFAULT);
	FormatEx(s, sizeof(s), "%T", "tank_param", client);
	menu.SetTitle(s);
	FormatEx(s, sizeof(s), "%T", "set_count", client, GetTankCountToSpawn());
	menu.AddItem("1", s);
	FormatEx(s, sizeof(s), "%T", "set_hp", client, health);
	menu.AddItem("2", s);
	if( HasCreateTankAccess(client) ) {
		menu.AddItem("", "---------------------------------", ITEMDRAW_DISABLED);
		FormatEx(s, sizeof(s), "%T", "spawn_tank", client);
		menu.AddItem("3", s);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuMain(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char nAction[5];
			menu.GetItem(ItemIndex, nAction, sizeof(nAction));
			
			switch( StringToInt(nAction) ) {
				case 1: { ShowMenuCount(client); }
				case 2: { ShowMenuHP(client); }
				case 3: {
					if( !g_hCvarOneTankAlive.BoolValue || GetTankCount() == 0 )
					{
						g_bTankBeenSpawn = true;
						delete g_hTimerSafeArea;
						SetMaxInfectedBounds(true);
						ExecuteCheatCommand(client, g_bLeft4Dead2 ? "z_spawn_old" : "z_spawn", "tank", "");
						SetMaxInfectedBounds(false);
						g_bTankBeenSpawn = false;
					}
					vMenuTankSpawn(client);
				}
			}
		}
	}
	return 0;
}

void ShowMenuCount(int client, int index = 0)
{
	static char s[4], m[32];
	int aCnt[] = {1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,25,30,40,50};
	Menu menu = new Menu(MenuHandler_MenuCount, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Select_Quantity", client); // "Select the quantity of tanks:"
	for (int i = 0; i < sizeof(aCnt); i++) {
		IntToString (aCnt[i], s, sizeof(s));
		FormatEx(m, sizeof(m), "%T", "n_tanks", client, aCnt[i]);
		menu.AddItem(s, m);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuCount(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				vMenuTankSpawn(param1);
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char nAction[5];
			menu.GetItem(ItemIndex, nAction, sizeof(nAction));
			
			int tanks = StringToInt(nAction);
			if( !StartVote(client, tanks, true) )
				ShowMenuCount(client, menu.Selection);
		}
	}
	return 0;
}

void SetTanksCount(int iTanks)
{
	g_ConVarCount.Flags &= ~FCVAR_NOTIFY;
	g_ConVarCount.IntValue = iTanks;
	g_ConVarCount.Flags |= FCVAR_NOTIFY;
	CPrintToChatAll("%t", "count_is_set", iTanks); // "\x05Tanks count in wave is now: \x04%i", iTanks);
	g_bApplyMenuCount = true; // to overwrite balancer values
}

bool StartVote(int client, int iValue, bool bVoteCount)
{
	static int iLastTimeCount[MAXPLAYERS+1];
	static int iLastTimeHP[MAXPLAYERS+1];
	
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(client, "%t", "vote_in_progress");
		LogVoteAction(client, "[DENY] Reason: another vote is in progress.");
		return false;
	}
	if( !HasVoteAccess(client) ) {
		CPrintToChat(client, "%t", "no_access");
		LogVoteAction(client, "[NO ACCESS]");
		return false;
	}
	if( bVoteCount ) {
		if( iLastTimeCount[client] != 0 )
		{
			if( iLastTimeCount[client] + g_hCvarVoteDelay.IntValue > GetTime() && !IsClientRootAdmin(client) ) {
				CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
				LogVoteAction(client, "[DENY] Reason: too often.");
				return false;
			}
		}
		iLastTimeCount[client] = GetTime();
	}
	else {
		if( iLastTimeHP[client] != 0 )
		{
			if( iLastTimeHP[client] + g_hCvarVoteDelay.IntValue > GetTime() && !IsClientRootAdmin(client) ) {
				CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
				LogVoteAction(client, "[DENY] Reason: too often.");
				return false;
			}
		}
		iLastTimeHP[client] = GetTime();
	}
	/*
	if (GetSurvivorsCount() == 1) {
		if (bVoteCount)
			SetTanksCount(iValue);
		else
			SetTanksHP(iValue);
		return false;
	}
	*/
	if( g_iVotesDone[client] >= g_hCvarVoteMaxCount.IntValue )
	{
		CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
		LogVoteAction(client, "[DENY] Reason: too often.");
		return false;
	}
	g_iVotesDone[client] ++;
	
	Menu menu = new Menu(Handle_VoteTank, MenuAction_DisplayItem | MenuAction_Display);
	if( bVoteCount ) {
		menu.SetTitle("tank_count_vote");
		g_iVoteType = 1;
		CPrintHintTextToAll("%t", "vote_count", iValue); // "Vote for tanks count: %i"
		LogVoteAction(client, "[STARTED] Vote count: %i by", iValue);
	}
	else {
		menu.SetTitle("tank_hp_vote");
		g_iVoteType = 2;
		CPrintHintTextToAll("%t", "vote_hp", iValue); // "Vote for tanks HP: %i"
		LogVoteAction(client, "[STARTED] Vote hp: %i by", iValue);
	}
	if( view_as<INFO_LEVEL>(g_hCvarInfoLevel.IntValue) & INFO_LEVEL_SERVER )
	{
		PrintToServer("Vote for tanks started by: %N. New value: %i", client, iValue);
	}
	if( view_as<INFO_LEVEL>(g_hCvarInfoLevel.IntValue) & INFO_LEVEL_CONSOLE )
	{
		PrintToConsoleAll("Vote for tanks started by: %N. New value: %i", client, iValue);
	}
	static char s[16];
	IntToString(iValue, s, sizeof(s));
	menu.AddItem(s, "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	g_iValue = iValue;

	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu);
	return true;
}

public Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
	return Plugin_Continue;
}

public int Handle_VoteTank(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[64], buffer[255];

	switch (action)
	{
		case MenuAction_End: {
			if( g_bVoteInProgress ) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				if( g_bVotepass )
					Handler_PostVoteAction(true);
				else if( g_bVeto )
					Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
			delete menu;
		}
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if( (param1 == 0 || g_bVotepass) && !g_bVeto ) {
				Handler_PostVoteAction(true);
			}
			else {
				Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			FormatEx(buffer, sizeof(buffer), "%T", display, param1);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			menu.GetItem(0, display, sizeof(display));
			FormatEx(buffer, sizeof(buffer), "%T: %s", g_iVoteType == 1 ? "tank_count_vote" : "tank_hp_vote", param1, display);
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( bVoteSuccess ) {
		LogVoteAction(0, "[VOTE SUCCESS]");
		CPrintToChatAll("%t", "vote_success");
		if( g_iValue < 100 )
			SetTanksCount(g_iValue);
		else
			SetTanksHP(g_iValue);
	}
	else {
		LogVoteAction(0, "[VOTE FAILED]");
		CPrintToChatAll("%t", "vote_failed");
	}
	g_bVoteInProgress = false;
}

void ShowMenuHP(int client, int index = 0)
{
	Menu menu = new Menu(MenuHandler_MenuHP, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Select_HP", client); // "Select the health of the tanks:"
	menu.AddItem("5000", "5 K HP");
	menu.AddItem("10000", "10 K HP");
	menu.AddItem("20000", "20 K HP");
	menu.AddItem("30000", "30 K HP");
	menu.AddItem("40000", "40 K HP");
	menu.AddItem("50000", "50 K HP");
	menu.AddItem("65000", "65 K HP");
	menu.AddItem("80000", "80 K HP");
	menu.AddItem("100000", "100 K HP");
	menu.AddItem("200000", "200 K HP");
	menu.AddItem("500000", "500 K HP");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuHP(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Cancel:
			if( param2 == MenuCancel_ExitBack )
				Command_MenuTankSpawn(param1, 0);
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char nAction[16];
			menu.GetItem(ItemIndex, nAction, sizeof(nAction));
			
			int hp = StringToInt(nAction);
			if( !StartVote(client, hp, false) )
				ShowMenuHP(client, menu.Selection);
		}
	}
	return 0;
}

void SetTanksHP(int hp)
{
	g_ConVarHP.Flags &= ~FCVAR_NOTIFY;
	g_ConVarHP.IntValue = hp;
	g_ConVarHP.Flags |= FCVAR_NOTIFY;
	CPrintToChatAll("%t", "hp_is_set", hp); //"\x05Tanks health is now: \x04%i"
	g_bApplyMenuHealth = true; // to overwrite balancer values
}

/* ===================================================================================
									E V E N T S
====================================================================================== */

public void Event_VehicleLeaving(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_bVehicleLeaving = true;
}

public void Event_TankKilled(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_iTanksKilled++;
	
	if( GetTankCount() == 0 )
	{
		g_iLastTimeDeadTank = GetTime();
	}
}

public void Event_RoundEnd(Event event, const char[] sEvName, bool bDontBroadcast)
{
	OnMapEnd();
}

public void OnMapStart()
{
	GetCurrentMap(g_sMap, sizeof g_sMap);
	g_bFirstMap = IsFirstMap();
	g_bFinale = IsFinaleMap();
	
	g_iDirectorWavesInterval = g_bFinale ? 
		g_hCvarDirectorWavesInterval_Fin.IntValue : 
		GetRandomInt(g_hCvarDirectorWavesInterval_Min.IntValue, g_hCvarDirectorWavesInterval_Max.IntValue);
		
	// hack - give X seconds relax after map started
	g_iLastTimeDeadTank = GetTime() - g_iDirectorWavesInterval + g_hCvarMapStartRelax.IntValue;
}

public void OnMapEnd()
{
	#if( DEBUG )
		LogError("OnMapEnd");
	#endif
	if( g_bRoundStarted ) {
		PreserveCvar(g_ConVarCount, true);
		PreserveCvar(g_ConVarHP, true);
	}
	g_bRoundStarted = false;
	g_bDuplicateTank = true;
	g_bApplyMenuCount = false;
	g_bApplyMenuHealth = false;
	g_iTanksKilled = 0;
	g_iTanksRequired = 0;
	g_bTankSpawnedThisRound = false;
	delete g_hTimerSafeArea;
	delete g_hTimerSpawnTanksDelay;
	delete g_hTimerSpawnTanks;
	delete g_hTimerFirstTank;
	SetMaxInfectedBounds(false);
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_iVotesDone[i] = 0;
	}
	g_bVehicleLeaving = false;
	g_iLastTimeDeadTank = 0;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	g_iVotesDone[GetClientOfUserId(event.GetInt("userid"))] = 0;
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool dontBroadcast) 
{
	if( !g_ConVarEnable.BoolValue || !g_bRoundStarted || !IsAllowedGameMode() ) return;
	
	g_bTankSpawnedThisRound = true;
	CreateTimer(0.1, Timer_OnTankSpawn, hEvent.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_OnTankSpawn(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	#if (DEBUG)
		PrintToChatAll("[Tank] Found new tank. Id: %i", client);
	#endif
	
	if( client && IsClientInGame(client) )
	{
		// Hard limit for this server style: allow director Tanks, but never allow 2 living Tanks at once.
		if( g_hCvarOneTankAlive.BoolValue && GetTankCount() > 1 )
		{
			KickClient(client);
			return Plugin_Continue;
		}

		//PrintToChatAll("fm? %b, over? %b, dupl? %b", g_bFirstMap, g_bTankBeenSpawn, g_bDuplicateTank);
		
		/*
		if( g_bFirstMap && !g_bTankBeenSpawn && g_bDuplicateTank ) { // on first map, first spawn is allowed to do using this plugin only!
			if ( (0 != strcmp(g_sMap, "l4d_river01_docks", false)) &&
				 (0 != strcmp(g_sMap, "c7m1_docks", false)) ) { // tank in container
				KickClient(client); // kick director tank
				return;
			}
		}
		*/
		
		// set duplication timer
		if( g_bDuplicateTank ) // default == true (which means - allow to start new duplication sequence)
		{
			if( g_iLastTimeDeadTank != 0 )
			{
				// kick first tank in the new wave if timing doesn't meet
				if( g_iLastTimeDeadTank + g_iDirectorWavesInterval > GetTime() ) {
					KickClient(client);
					return Plugin_Continue;
				}
			}
			
			if( g_ConVarEnableDuplicate.BoolValue )
			{
				if (! (g_hCvarIngoneRush.BoolValue && GetTankCount() > 1) )
				{
					SpawnManyTanks(g_ConVarSpawnInterval.FloatValue, -1); // -1: include director tank in total tank counting
				}
			}
		}
		
		// adjust hp
		if( g_ConVarControlHP.BoolValue || g_bApplyMenuHealth ) {
			CreateTimer(0.3, Timer_TankHP, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {
			int iTanksPlanned = g_iTanksRequired - g_iTanksKilled;
			
			int iTanksCount = GetTankCount();
			if( iTanksPlanned <= 0 )
			{
				iTanksPlanned = iTanksCount;
			}
			
			if( g_ConVarAnnouncement.BoolValue )
			{
				int defhp = g_ConVarZTankHealth.IntValue;
				CPrintToChatAll("\x04%t %i/%i \x01%t: %i", "Tank", iTanksCount, iTanksPlanned, "health", defhp);
			}
		}
		
		//SetEntPropString(client, Prop_Data, "m_iName", "Tank");
	}
	return Plugin_Continue;
}

public Action Timer_TankHP(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		int iTanksPlanned = g_iTanksRequired - g_iTanksKilled;
		int iTanksCount = GetTankCount();
		if( iTanksPlanned <= 0 )
		{
			iTanksPlanned = iTanksCount;
		}
		
		int hp, defhp;
		
		defhp = g_ConVarZTankHealth.IntValue;
	
		if( g_ConVarControlHP.IntValue == 1 || g_bApplyMenuHealth ) // fixed hp or menu
		{
			hp = g_ConVarHP.IntValue;
			
			if( g_ConVarAnnouncement.BoolValue )
			{
				if( g_bApplyMenuHealth )
				{
					CPrintToChatAll("\x04%t %i/%i \x01%t: %i ==> \x04%i", "Tank", iTanksCount, iTanksPlanned, "health", defhp, hp);
				}
				else {
					CPrintToChatAll("\x04%t %i/%i \x01%t: \x04%i", "Tank", iTanksCount, iTanksPlanned, "health", hp);
				}
			}
		}
		else if ( g_ConVarControlHP.IntValue == 2 ) // balancer based
		{
			defhp = g_ConVarHP.IntValue;
			
			float pf = GetTankHP_PlayerFactor();
			float df = GetTankHP_DifficultyFactor();
			
			//PrintToChatAll("tank multiple - player f: %f, diff f: %f", pf, df);
			
			float m = pf * df;
			hp = RoundToCeil(defhp * m);
			
			if( g_ConVarAnnouncement.BoolValue )
			{
				CPrintToChatAll("\x04%t %i/%i \x01%t [x%.1f*%.1f\x01] %i ==> \x04%i", "Tank", iTanksCount, iTanksPlanned, "health", pf, df, defhp, hp);
			}
		}
		
		SetEntProp(client, Prop_Data, "m_iMaxHealth", hp);
		SetEntProp(client, Prop_Data, "m_iHealth", hp);
		
		#if (DEBUG)
			PrintToChatAll("[TankOnSpawn] Tank HP is set to %i", hp);
		#endif
	}
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bTankBeenSpawn = false;
	g_bTankSpawnedThisRound = false;
	g_bFirstMap = IsFirstMap();
	
	if( !g_bRoundStarted ) {
		g_bRoundStarted = true;
		
		if( IsAllowedGameMode() ) {
			bool bShouldStartSafeAreaTimer = false;

			// New behavior: guarantee one Tank on every chapter after survivors leave the saferoom.
			if( g_hCvarForceEveryMap.BoolValue ) {
				bShouldStartSafeAreaTimer = true;
			}
			// Original behavior fallback: first map only, using the old chance cvar.
			else if( g_bFirstMap && GetRandomInt(1, 100) <= g_ConVarChanceFM.IntValue ) {
				bShouldStartSafeAreaTimer = true;
			}

			if( bShouldStartSafeAreaTimer ) {
				#if (DEBUG)
					PrintToChatAll("[TankOnSpawn] Safe area timer started for this chapter.");
				#endif

				g_iEntPlayerResource = GetEntityPlayerResource();
				g_hTimerSafeArea = CreateTimer(5.0, Timer_PlayerLeftStart, _, TIMER_REPEAT);
			}
		}
		CreateTimer(1.0, Timer_EnforceCvars, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_EnforceCvars(Handle timer)
{
	PreserveCvar(g_ConVarCount, false);
	PreserveCvar(g_ConVarHP, false);
	return Plugin_Continue;
}

bool IsAllowedGameMode()
{
	if( !g_hCvarVersusOnly.BoolValue )
		return true;

	if( g_hCvarGameMode == null )
		return true;

	static char sMode[64];
	g_hCvarGameMode.GetString(sMode, sizeof(sMode));

	return StrContains(sMode, "versus", false) != -1;
}

bool IsFirstMap()
{
	#if defined _l4dh_included
	
		if( g_bLeft4DHooks && g_bLeft4Dead2 )
		{
			return L4D_IsFirstMapInScenario();
		}
		else {
			return IsFirstMap_Old();
		}
	#else
		return IsFirstMap_Old();
	#endif
}

bool IsFirstMap_Old()
{
	if( g_bLeft4Dead2 )
	{
		if (0 == strcmp(g_sMap, "c1m1_hotel", false) ||
			0 == strcmp(g_sMap, "c2m1_highway", false) ||
			0 == strcmp(g_sMap, "c3m1_plankcountry", false) ||
			0 == strcmp(g_sMap, "c4m1_milltown_a", false) ||
			0 == strcmp(g_sMap, "c5m1_waterfront", false) ||
			0 == strcmp(g_sMap, "c6m1_riverbank", false) ||
			0 == strcmp(g_sMap, "c7m1_docks", false) ||
			0 == strcmp(g_sMap, "c8m1_apartment", false) ||
			0 == strcmp(g_sMap, "c9m1_alleys", false) ||
			0 == strcmp(g_sMap, "c10m1_caves", false) ||
			0 == strcmp(g_sMap, "c11m1_greenhouse", false) ||
			0 == strcmp(g_sMap, "C12m1_hilltop", false) ||
			0 == strcmp(g_sMap, "c13m1_alpinecreek", false) ||
			0 == strcmp(g_sMap, "c14m1_junkyard", false)) {
			
			return true;
		}
		return false;
	}
	else {
		if (0 == strcmp(g_sMap, "l4d_hospital01_apartment", false) ||
			0 == strcmp(g_sMap, "l4d_garage01_alleys", false) ||
			0 == strcmp(g_sMap, "l4d_smalltown01_caves", false) ||
			0 == strcmp(g_sMap, "l4d_airport01_greenhouse", false) ||
			0 == strcmp(g_sMap, "l4d_farm01_hilltop", false) ||
			0 == strcmp(g_sMap, "l4d_river01_docks", false)) {
		
			return true;
		}
		return false;
	}
}

/* ===================================================================================
									T I M E R S
====================================================================================== */

public Action Timer_PlayerLeftStart(Handle hTimer)
{
	if( LeftStartArea() )
	{
		DoorOpened();
		
		#if (DEBUG)
			PrintToChatAll("Client left safe area.");
		#endif
		
		g_hTimerSafeArea = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void DoorOpened()
{
	float fDelay = GetRandomFloat(g_ConVarMinDelay.FloatValue, g_ConVarMaxDelay.FloatValue);
	g_hTimerFirstTank = CreateTimer(fDelay, Timer_SpawnTankSingle);
}

void SpawnManyTanks(float fStartDelay, int delta)
{
	if( g_bVehicleLeaving )
		return;

	g_iTanksKilled = 0;
	int iTanksToSpawn = GetTankCountToSpawn() + delta;
	if( iTanksToSpawn < 0 )
		iTanksToSpawn = 0;
	
	// including tank that is already in the field
	if( g_iTanksRequired == 0 ) {
		g_iTanksRequired = iTanksToSpawn + GetTankCount();
	}
	else {
		g_iTanksRequired += iTanksToSpawn;
	}
	
	#if (DEBUG)
		PrintToChatAll("[Tank] begin spawn. Should dupl? %b, Cnt: %i", g_bDuplicateTank, iTanksToSpawn);
	#endif
	
	if( iTanksToSpawn > 0 ) {
		// to prevent plugin from recurse duplicating own new tanks
		g_bDuplicateTank = false;
		
		SetMaxInfectedBounds();
		
		if( g_hTimerSpawnTanksDelay == INVALID_HANDLE && g_hTimerSpawnTanks == INVALID_HANDLE ) {
			g_hTimerSpawnTanksDelay = CreateTimer(fStartDelay, Timer_SpawnManyTanks);
		}
	}
}

public Action Timer_SpawnManyTanks(Handle timer)
{
	g_hTimerSpawnTanksDelay = INVALID_HANDLE;
	g_hTimerSpawnTanks = CreateTimer(g_ConVarSpawnInterval.FloatValue, Timer_SpawnTank, _, TIMER_REPEAT);
	return Plugin_Continue;
}

public Action Timer_SpawnTank(Handle timer)
{
	if( g_bVehicleLeaving ) {
		g_hTimerSpawnTanks = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int iTanks = GetTankCount();
	
	if( iTanks < g_ConVarCountLimit.IntValue )
	{
		vSpawnInfected("tank");
		iTanks = GetTankCount();
	}
	
	if( iTanks >= g_iTanksRequired - g_iTanksKilled ) {
		g_hTimerSpawnTanks = INVALID_HANDLE;
		#if (DEBUG)
			PrintToChatAll("Total tanks now is: %i. Req: %i. Killed: %i", iTanks, g_iTanksRequired, g_iTanksKilled);
		#endif // 3 6 3
		SetMaxInfectedBounds(false);
		g_bDuplicateTank = true;
		g_iTanksKilled = 0;
		g_iTanksRequired = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_SpawnTankSingle(Handle timer)
{
	#if (DEBUG)
		PrintToChatAll("Timer_SpawnTankSingle");
	#endif

	// Do not interfere with a normal director Tank. If the director already spawned
	// a Tank this chapter, or if a Tank is currently alive, this chapter is covered.
	if( IsAllowedGameMode() && !g_bTankSpawnedThisRound && GetTankCount() == 0 )
	{
		g_bTankBeenSpawn = true;
		vSpawnInfected("tank");
		g_bTankBeenSpawn = false;
	}

	g_hTimerFirstTank = INVALID_HANDLE;
	return Plugin_Continue;
}

/* ===================================================================================
									S T O C K S
====================================================================================== */

void vSpawnInfected(char[] name, bool bAuto = true)
{
	#if (DEBUG)
		PrintToChatAll("Attempt: %s ++", name);
	#endif
	
	if( g_hCvarOneTankAlive.BoolValue && StrEqual(name, "tank", false) && GetTankCount() > 0 )
	{
		return;
	}

	int client = GetAnyClient();
	if( client != 0 )
	{
		SetMaxInfectedBounds();
		ExecuteCheatCommand(client, g_bLeft4Dead2 ? "z_spawn_old" : "z_spawn", name, bAuto ? "auto" : "");
	}
}

void ExecuteCheatCommand(int client, char[] command, char[] param1, char[] param2) {
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, param1, param2);
	SetCommandFlags(command, flags | GetCommandFlags(command));
}

int GetAnyClient()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) )
			return i;
	}
	return 0;
}

bool LeftStartArea()
{
	if (g_iEntPlayerResource && g_iEntPlayerResource != -1)
	{
		if( GetEntData(g_iEntPlayerResource, g_iOffsetLeftSafeArea) == 1 ) return true;
	}
	return false;
}

int GetEntityPlayerResource()
{
	int ent = -1, maxents = GetMaxEntities();
	for( int i = MaxClients + 1; i <= maxents; i++ )
	{
		if( IsValidEntity(i) )
		{
			static char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if( 0 == strcmp(netclass, "CTerrorPlayerResource") )
			{
				ent = i;
				break;
			}
		}
	}
	return ent;
}

stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}

int GetPlayersCount()
{
	int iPlayersCount = 0;
	
	for( int i = 1; i <= MaxClients; i++ ) {
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 3 )
			iPlayersCount++;
	}
	return iPlayersCount;
}

stock int GetSurvivorsCount()
{
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 )
			cnt++;
	return cnt;
}

int GetTankCount()
{
	int iTanks = 0;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsTank(i) && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 0 )
			iTanks++;
			
	return iTanks;
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

stock char[] Translate(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    return buffer;
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void PrintToAdmin(const char[] format, any ...)
{
    static char buffer[192];
    VFormat(buffer, sizeof(buffer), format, 2);
    for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && IsClientRootAdmin(i) )
		{
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if( !g_hCvarLog.BoolValue )
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFile(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFileEx(g_sLog, buffer);
	}
}

stock bool IsFinaleMap()
{
	#if defined _l4dh_included
	
		if( g_bLeft4DHooks )
		{
			return L4D_IsMissionFinalMap();
		}
		else {
			return IsFinaleMap_Old();
		}
	#else
		return IsFinaleMap_Old();
	#endif
}

bool IsFinaleMap_Old()
{
	return FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1;
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if( g_bTankBeenSpawn )
	{
		if( strcmp(key, "TankLimit", false) == 0 )
		{
			retVal = g_ConVarCountLimit.IntValue;
			#if (DEBUG)
				PrintToChatAll("Explicit set tank limit");
			#endif
			return Plugin_Handled;
		}
		/* Other interesting DVars:
			 - MaxSpecials
			 - EscapeSpawnTanks
			 - ProhibitBosses
		*/
	}
	return Plugin_Continue;
}

public MRESReturn GetScriptValueInt(Handle hReturn, Handle hParams)
{
	if( !g_bTankBeenSpawn )
		return MRES_Ignored;
	
	static char key[64];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	int a2 = DHookGetParam(hParams, 2);

	if( L4D_OnGetScriptValueInt(key, a2) == Plugin_Handled )
	{
		DHookSetParam(hParams, 2, a2);
		DHookSetReturn(hReturn, a2);
		return MRES_ChangedOverride;
	}
	
	return MRES_Ignored;
}

/* ===================================================================================
									B A L A N C E R
====================================================================================== */

int GetTankCountToSpawn()
{
	if( g_ConVarCountMode.IntValue == 1 || g_bApplyMenuCount ) {
		return g_ConVarCount.IntValue;
	}

	int iPlayersCount = GetPlayersCount();
	int iTanks;
	
	if( iPlayersCount )
	{
		if( iPlayersCount > MAX_PLAYERS_CVAR )
			iPlayersCount = MAX_PLAYERS_CVAR;
		
		iTanks = g_hCvarTanksOnPlayers[iPlayersCount].IntValue;
	}
	
	if( g_bEasy ) {
		iTanks += g_hCvarAddTanksOnEasy.IntValue;
	}
	else if( g_bNormal ) {
		iTanks += g_hCvarAddTanksOnNormal.IntValue;
	}
	else if( g_bHard ) {
		iTanks += g_hCvarAddTanksOnHard.IntValue;
	}
	else if( g_bExpert ) {
		iTanks += g_hCvarAddTanksOnExpert.IntValue;
	}
	
	if( g_bFirstMap )
	{
		iTanks += g_hCvarAddTanksOnFirstMap.IntValue;
	}
	if( g_bFinale )
	{
		iTanks += g_hCvarAddFinaleTanks.IntValue;
	}
	
	if( iTanks == 0 )
		iTanks = 1;
	
	return iTanks;
}

float GetTankHP_PlayerFactor()
{
	int iPlayersCount = GetPlayersCount();
	
	if( iPlayersCount > MAX_PLAYERS_CVAR )
		iPlayersCount = MAX_PLAYERS_CVAR;

	if( iPlayersCount == 0 )
		iPlayersCount = 1;
	
	return g_hCvarHpMultiplier[iPlayersCount].FloatValue;
}

float GetTankHP_DifficultyFactor()
{
	float m;
	if( g_bExpert ) {
		m = g_hCvarHpFactorExpert.FloatValue;
	}
	else if( g_bHard ) {
		m = g_hCvarHpFactorHard.FloatValue;
	}
	else if( g_bNormal ) {
		m = g_hCvarHpFactorNormal.FloatValue;
	}
	else if( g_bEasy ) {
		m = g_hCvarHpFactorEasy.FloatValue;
	}
	return m;
}

int iGetListenServerHost(int client, bool dedicated) // Thanks to @Marttt
{
	if( client == 0 && !dedicated )
	{
		int iManager = FindEntityByClassname(-1, "terror_player_manager");
		if( iManager != -1 && IsValidEntity(iManager) )
		{
			int iHostOffset = FindSendPropInfo("CTerrorPlayerResource", "m_listenServerHost");
			if( iHostOffset != -1 )
			{
				bool bHost[MAXPLAYERS + 1];
				GetEntDataArray(iManager, iHostOffset, bHost, (MAXPLAYERS + 1), 1);
				for( int iPlayer = 1; iPlayer < sizeof(bHost); iPlayer++ )
				{
					if( bHost[iPlayer] )
					{
						return iPlayer;
					}
				}
			}
		}
	}
	return client;
}
