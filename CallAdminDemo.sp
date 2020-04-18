#include <sourcemod>
#include <calladmin>
#include <multicolors>

bool g_bIsTVRecording = false;

ConVar g_cvarDemoPath;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "CallAdmin Demo",
	author = "Nano",
	description = "Start recording a demo when someone is reported.",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	g_cvarDemoPath = CreateConVar("sm_calladmin_demo_path", ".", "Path to store recorded demos by CallAdmin (let . to upload demos to the cstrike/csgo folder)");
	
	AutoExecConfig(true, "CallAdminDemo");
	
	char sPath[PLATFORM_MAX_PATH];
	g_cvarDemoPath.GetString(sPath, sizeof(sPath));
	if(!DirExists(sPath))
	{
		InitDirectory(sPath);
	}
	
	g_cvarDemoPath.AddChangeHook(OnConVarChanged);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char [] newValue)
{
	if(convar == g_cvarDemoPath)
	{
		if(!DirExists(newValue))
		{
			InitDirectory(newValue);
		}
	}
}

public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
	if(!g_bIsTVRecording)
	{
		StartRecordingDemo();
	}
	else
	{
		CPrintToChatAll("{green}[CallAdminDemo]{default} STV is {green}already recording");
	}
}

public void OnMapEnd()
{
	StopRecordDemo();
}

void StartRecordingDemo()
{
	char sPath[PLATFORM_MAX_PATH];
	char sTime[16];
	char sMap[32];

	g_bIsTVRecording = true;
	g_cvarDemoPath.GetString(sPath, sizeof(sPath));
	FormatTime(sTime, sizeof(sTime), "%d-%m___%H-%M", GetTime());
	GetCurrentMap(sMap, sizeof(sMap));
	ReplaceString(sMap, sizeof(sMap), "/", "-", false);	
	
	CPrintToChatAll("{green}[CallAdminDemo]{default} SourceTV started recording due a player's report");

	ServerCommand("tv_record \"%s/report_%s_%s\"", sPath, sTime, sMap);
}

void StopRecordDemo()
{
	if(g_bIsTVRecording)
	{
		ServerCommand("tv_stoprecord");
		g_bIsTVRecording = false;
	}
}

void InitDirectory(const char[] sDir)
{
	char sPieces[32][PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	int iNumPieces = ExplodeString(sDir, "/", sPieces, sizeof(sPieces), sizeof(sPieces[]));

	for(int i = 0; i < iNumPieces; i++)
	{
		Format(sPath, sizeof(sPath), "%s/%s", sPath, sPieces[i]);
		if(!DirExists(sPath))
		{
			CreateDirectory(sPath, 509);
		}
	}
}
