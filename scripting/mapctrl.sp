#pragma semicolon 1
#include <sourcemod>

char mapctrl_GameMode[24];
char mapctrl_KeyValuesFilePath[128];
char mapctrl_CurrentMap[48];
char mapctrl_NextMap[48];
char mapctrl_NextMapName[48];
bool mapctrl_IsCoop = false;
KeyValues mapctrl_KeyValues;

public Plugin myinfo =
{
    name = "MapCtrl",
    author = "Lyric",
    description = "L4D2 Coop Map Control",
    version = "0.2",
    url = "https://github.com/scooderic"
};

public void OnPluginStart()
{
    mapctrl_KeyValues = CreateKeyValues("MapCtrlMapQueue");
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("finale_win", Event_FinalWin, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
    mapctrl_IsCoop = false;
    GetCurrentMap(mapctrl_CurrentMap, sizeof(mapctrl_CurrentMap));
    GetConVarString(FindConVar("mp_gamemode"), mapctrl_GameMode, sizeof(mapctrl_GameMode));
    if (StrEqual(mapctrl_GameMode, "coop", true))
    {
        mapctrl_IsCoop = true;
    }
    if (StrEqual(mapctrl_GameMode, "realism", true))
    {
        mapctrl_IsCoop = true;
    }
    while (KvGotoFirstSubKey(mapctrl_KeyValues))
    {
        KvDeleteThis(mapctrl_KeyValues);
        KvRewind(mapctrl_KeyValues);
    }
    BuildPath(Path_SM, mapctrl_KeyValuesFilePath, 128, "data/mapctrl.txt");
    if (!FileToKeyValues(mapctrl_KeyValues, mapctrl_KeyValuesFilePath))
    {
        SetFailState("File 'data/mapctrl.txt' not found, Shutdown.");
    }
    mapctrl_NextMap = "none";
    mapctrl_NextMapName = "(None)";
    KvRewind(mapctrl_KeyValues);
    if (KvJumpToKey(mapctrl_KeyValues, mapctrl_CurrentMap, false))
    {
        KvGetString(mapctrl_KeyValues, "next_map", mapctrl_NextMap, sizeof(mapctrl_NextMap), "none");
        KvGetString(mapctrl_KeyValues, "next_map_name", mapctrl_NextMapName, sizeof(mapctrl_NextMapName), "(None)");
    }
    KvRewind(mapctrl_KeyValues);
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        CreateTimer(10.0, Timer_Announce, client, 0);
    }
}

public Action Timer_Announce(Handle timer, any client)
{
    if (mapctrl_IsCoop && IsClientInGame(client))
    {
        PrintToChat(client, "\x04[MapCtrl]\x03 当前地图：%s", mapctrl_CurrentMap);
        if (!StrEqual(mapctrl_NextMap, "none"))
        {
            PrintToChat(client, "\x04[MapCtrl]\x03 下个战役：\x04%s", mapctrl_NextMapName);
        }
        /* else
        {
            PrintToChat(client, "\x04[MapCtrl]\x03 加油，奥利给！ ");
        } */
    }
}

public Action Timer_BeforeChangeMap(Handle timer)
{
    PrintToChatAll("\x04[MapCtrl]\x03 下个战役：\x04%s", mapctrl_NextMapName);
    PrintToChatAll("\x04[MapCtrl]\x03 %s", mapctrl_NextMap);
    CreateTimer(10.0, Timer_DoChangeMap, 0, 0);
    return Plugin_Stop;
}

public Action Timer_DoChangeMap(Handle timer)
{
    if (IsMapValid(mapctrl_NextMap))
    {
        ServerCommand("changelevel %s", mapctrl_NextMap);
    }
    else
    {
        PrintToChatAll("\x04[MapCtrl]\x03 没有找到地图：\x04%s\x03，再见 ", mapctrl_NextMapName);
    }
    return Plugin_Stop;
}

public Action Timer_FinalAnnounce(Handle timer)
{
    PrintToChatAll("\x04[MapCtrl]\x03 最后祝您，身体健康，再见 ");
    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    GetCurrentMap(mapctrl_CurrentMap, sizeof(mapctrl_CurrentMap));
}

public void Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
    if (mapctrl_IsCoop)
    {
        if (!StrEqual(mapctrl_NextMap, "none", true))
        {
            PrintToChatAll("\x04[MapCtrl]\x03 已完成本战役，30 秒后将自动换图...");
            CreateTimer(20.0, Timer_BeforeChangeMap, 0, 0);
        }
        else 
        {
            PrintToChatAll("\x04[MapCtrl]\x03 已完成所有战役，自动换图已经结束 ");
            PrintToChatAll("\x04[MapCtrl]\x03 自动换图 v0.2 by Lyric");
            CreateTimer(20.0, Timer_FinalAnnounce, 0, 0);
        }
    }
}
