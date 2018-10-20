#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>



public Plugin myinfo = 
{
	name = "GOKZ Player Models", 
	author = "DanZay", 
	description = "GOKZ Player Models Module", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATE_URL "http://updater.gokz.org/gokz-playermodels.txt"

ConVar gCV_gokz_player_models;
ConVar gCV_gokz_player_models_alpha;
ConVar gCV_sv_disable_immunity_alpha;



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	RegPluginLibrary("gokz-playermodels");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateHooks();
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}



// =========================  CLIENT  ========================= //

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		UpdatePlayerModel(client);
	}
}



// =========================  OTHER  ========================= //

public void OnMapStart()
{
	PrecacheModels();
}



// =========================  PRIVATE  ========================= //

static void CreateConVars()
{
	gCV_gokz_player_models = CreateConVar("gokz_player_models", "1", "Whether GOKZ sets player's models upon spawning.", _, true, 0.0, true, 1.0);
	gCV_gokz_player_models_alpha = CreateConVar("gokz_player_models_alpha", "65", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_sv_disable_immunity_alpha = FindConVar("sv_disable_immunity_alpha");
	
	gCV_gokz_player_models_alpha.AddChangeHook(OnConVarChanged);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_player_models_alpha)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				UpdatePlayerModelAlpha(client);
			}
		}
	}
}

static void CreateHooks()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

static void PrecacheModels()
{
	PrecachePlayerModels();
}



// =========================  PLAYER MODELS  ========================= //

#define PLAYER_MODEL_T "models/player/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT "models/player/ctm_idf_variantc.mdl"

void UpdatePlayerModel(int client)
{
	if (gCV_gokz_player_models.BoolValue)
	{
		// Do this after a delay so that gloves apply correctly after spawning
		CreateTimer(0.1, Timer_UpdatePlayerModel, GetClientUserId(client));
	}
}

public Action Timer_UpdatePlayerModel(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	switch (GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, PLAYER_MODEL_T);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, PLAYER_MODEL_CT);
		}
	}
	
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}

void PrecachePlayerModels()
{
	gCV_sv_disable_immunity_alpha.IntValue = 1; // Ensures player transparency works	
	
	PrecacheModel(PLAYER_MODEL_T, true);
	PrecacheModel(PLAYER_MODEL_CT, true);
} 