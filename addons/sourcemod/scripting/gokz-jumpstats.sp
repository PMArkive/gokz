#include <sourcemod>

#include <sdkhooks>

#include <emitsoundany>
#include <gokz>

#include <movementapi>
#include <gokz/core>
#include <gokz/jumpstats>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Jumpstats", 
	author = "DanZay", 
	description = "GOKZ Jumpstats Module", 
	version = "0.14.0", 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define BHOP_ON_GROUND_TICKS 5
#define WEIRDJUMP_MAX_FALL_OFFSET 64.0
#define MAX_TRACKED_STRAFES 32

bool gB_LateLoad;
int gI_TouchingEntities[MAXPLAYERS + 1];

#include "gokz-jumpstats/api.sp"
#include "gokz-jumpstats/distancetiers.sp"
#include "gokz-jumpstats/jumpreporting.sp"
#include "gokz-jumpstats/jumptracking.sp"



// =========================  PLUGIN  ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-jumpstats");
	gB_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	LoadTranslations("gokz-jumpstats.phrases");
	
	CreateGlobalForwards();
	
	if (gB_LateLoad)
	{
		OnLateLoad();
	}
}

void OnLateLoad()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}



// =========================  CLIENT  ========================= //

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	OnPlayerRunCmd_JumpTracking(client, tickcount);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouchPost, SDKHook_StartTouch_Callback);
	SDKHook(client, SDKHook_EndTouchPost, SDKHook_EndTouch_Callback);
}

public void SDKHook_StartTouch_Callback(int client, int touched)
{
	gI_TouchingEntities[client]++;
	OnStartTouch_JumpTracking(client);
}

public void SDKHook_EndTouch_Callback(int client, int touched)
{
	gI_TouchingEntities[client]--;
}



// =========================  MOVEMENTAPI  ========================= //

public void Movement_OnStartTouchGround(int client)
{
	OnStartTouchGround_JumpTracking(client);
}



// =========================  GOKZ  ========================= //

public void GOKZ_OnJumpValidated(int client, bool jumped, bool ladderJump)
{
	OnJumpValidated_JumpTracking(client, jumped, ladderJump);
}

public void GOKZ_OnJumpInvalidated(int client)
{
	OnJumpInvalidated_JumpTracking(client);
}

public void GOKZ_JS_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	OnLanding_JumpReporting(client, jumpType, distance, offset, height, preSpeed, maxSpeed, strafes, sync, duration);
}



// =========================  OTHER  ========================= //
public void OnMapStart()
{
	OnMapStart_DistanceTiers();
	OnMapStart_JumpReporting();
} 