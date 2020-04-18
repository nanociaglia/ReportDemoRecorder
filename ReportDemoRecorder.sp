#include <sourcemod>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <sourcebanspp>
#include <calladmin>
#include <sourcetvmanager>

bool g_bIsTVRecording = false;

char g_szLogFile[PLATFORM_MAX_PATH];

ConVar g_cvarRDREnable;
ConVar g_cvarRDRPath;
ConVar g_cvarRDRSystem;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Report Demo Recorder",
	author = "Nano",
	description = "Start recording a demo when someone is reported.",
	version = "2.0",
	url = "https://steamcommunity.com/id/nano2k06/"
};

public void OnPluginStart()
{
	g_cvarRDREnable = CreateConVar("sm_rdr_enable", "1", "Enable or disable the whole plugin (1 enabled | 0 disabled) - Default = 1");
	g_cvarRDRPath = CreateConVar("sm_rdr_path", ".", "Path to store recorded demos by CallAdmin (let . to upload demos to the cstrike/csgo folder)");
	g_cvarRDRSystem = CreateConVar("sm_rdr_system", "1", "Change the system to start recording demos (1 = CallAdmin | 2 = Sourceban Reports) - Default = 1");
	
	AutoExecConfig(true, "ReportDemoRecorder");
	
	char sPath[PLATFORM_MAX_PATH];
	g_cvarRDRPath.GetString(sPath, sizeof(sPath));
	if(!DirExists(sPath))
	{
		InitDirectory(sPath);
	}
	
	g_cvarRDRPath.AddChangeHook(OnConVarChanged);
	
	BuildPath(Path_SM, g_szLogFile, sizeof(g_szLogFile), "logs/ReportDemoRecorder.log");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char [] newValue)
{
	if(convar == g_cvarRDRPath)
	{
		if(!DirExists(newValue))
		{
			InitDirectory(newValue);
		}
	}
}

public void SourceTV_OnStartRecording(int iInstance, const char[] szFileName) 
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

	LogToFile(g_szLogFile, "Started to record a demo due a player's report: %s", szFileName);
}

public void SourceTV_OnStopRecording(int iInstance, const char[] szFileName)
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

	LogToFile(g_szLogFile, "Successfully recorded a report demo.");
}

public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

	if(g_cvarRDRSystem.IntValue == 2)
	{
		return;
	}

	if(!g_bIsTVRecording)
	{
		StartRecordingDemo();
	}
	else
	{
		CPrintToChatAll("{green}[ReportDemo]{default} STV is {green}already recording");
	}
}

public void SBPP_OnReportPlayer(int iReporter, int iTarget, const char[] sReason)
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

	if(g_cvarRDRSystem.IntValue == 1)
	{
		return;
	}

	if(!g_bIsTVRecording)
	{
		StartRecordingDemo();
	}
	else
	{
		CPrintToChatAll("{green}[ReportDemo]{default} STV is {green}already recording");
	}
}

public void OnMapEnd()
{
	StopRecordDemo();
}

void StartRecordingDemo()
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

	char sPath[PLATFORM_MAX_PATH];
	char sTime[16];
	char sMap[32];

	g_bIsTVRecording = true;
	g_cvarRDRPath.GetString(sPath, sizeof(sPath));
	FormatTime(sTime, sizeof(sTime), "%d-%m___%H-%M", GetTime());
	GetCurrentMap(sMap, sizeof(sMap));
	ReplaceString(sMap, sizeof(sMap), "/", "-", false);	
	
	CPrintToChatAll("{green}[ReportDemo]{default} SourceTV started recording due a player's report");

	ServerCommand("tv_record \"%s/report_%s_%s\"", sPath, sTime, sMap);
}

void StopRecordDemo()
{
	if(!g_cvarRDREnable.BoolValue)
	{
		return;
	}

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
