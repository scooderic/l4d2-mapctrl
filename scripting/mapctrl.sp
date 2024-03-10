#pragma semicolon 1
#include <sourcemod>

const int MAX_MAP_COUNT = 16;
const int MAX_MAP_NAME_LENGTH = 64;

char g_GameMode[24];
bool g_IsCoop = false;

// c1m4_atrium,c2m1_highway|c2m5_concert,c3m1_plankcountry|c3m4_plantation,c4m1_milltown_a|...
ConVar g_MapPairListCvar; char g_MapPairListStr[1024];

char g_MapPairList[MAX_MAP_COUNT][MAX_MAP_NAME_LENGTH];

// K: c1m4_atrium; V: c2m1_highway ...
StringMap g_MapMap;

char g_MapNameCharBuf[MAX_MAP_NAME_LENGTH];
char g_CurrentMap[MAX_MAP_NAME_LENGTH];
char g_NextMap[MAX_MAP_NAME_LENGTH];

public Plugin myinfo =
{
    name = "MapCtrl",
    author = "Lyric",
    description = "L4D2 Coop Map Control",
    version = "2.0.2",
    url = "https://github.com/scooderic"
};

public void OnPluginStart()
{
    g_MapMap = new StringMap();

    g_MapPairListCvar = CreateConVar("mapctrl_map_pair_list", "c1m4_atrium,c2m1_highway|c2m5_concert,c3m1_plankcountry|c3m4_plantation,c4m1_milltown_a", "map1_end,map2_start|map2_end,map3_start|map3_end,map4_start");
    HookConVarChange(g_MapPairListCvar, OnMapPairListChanged);
    GetConVarString(g_MapPairListCvar, g_MapPairListStr, sizeof(g_MapPairListStr));

    AutoExecConfig(true, "mapctrl");

    SetupMaps(g_MapPairListStr);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("finale_win", Event_FinalWin, EventHookMode_PostNoCopy);
}

public OnMapPairListChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
    strcopy(g_MapPairListStr, sizeof(g_MapPairListStr), newVal);
    SetupMaps(g_MapPairListStr);
}

void SetupMaps(const char[] mapPairListStr)
{
    if (strlen(mapPairListStr) > 3)
    {
        ExplodeString(mapPairListStr, "|", g_MapPairList, MAX_MAP_COUNT, MAX_MAP_NAME_LENGTH, false);

        int i = 0;
        while (i < MAX_MAP_COUNT)
        {
            strcopy(g_MapNameCharBuf, sizeof(g_MapNameCharBuf), g_MapPairList[i]);
            if (strlen(g_MapNameCharBuf) > 3)
            {
                char endMapName[MAX_MAP_NAME_LENGTH];
                SplitString(g_MapNameCharBuf, ",", endMapName, sizeof(endMapName));
                ReplaceString(g_MapNameCharBuf, sizeof(g_MapNameCharBuf), endMapName, "", true);
                if (strlen(g_MapNameCharBuf) > 1) g_MapMap.SetString(endMapName, g_MapNameCharBuf[1], true);
            }
            else break;
            i++;
        }
    }
}

public void OnMapStart()
{
    g_IsCoop = false;
    GetConVarString(FindConVar("mp_gamemode"), g_GameMode, sizeof(g_GameMode));
    if (StrEqual(g_GameMode, "coop", true) || StrEqual(g_GameMode, "realism", true)) g_IsCoop = true;

    g_CurrentMap = "";
    g_NextMap = "";
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    g_MapMap.GetString(g_CurrentMap, g_NextMap, sizeof(g_NextMap));
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        CreateTimer(10.0, Timer_Announce, client);
    }
}

public Action Timer_Announce(Handle timer, int client)
{
    if (g_IsCoop && IsClientInGame(client))
    {
        PrintToChat(client, "\x04[MapCtrl]\x03 当前地图：%s", g_CurrentMap);
        if (strlen(g_NextMap) > 0)
        {
            PrintToChat(client, "\x04[MapCtrl]\x03 下个地图：\x04%s", g_NextMap);
        }
    }
    return Plugin_Stop;
}

public Action Timer_BeforeChangeMap(Handle timer)
{
    PrintToChatAll("\x04[MapCtrl]\x03 下个地图：\x04%s", g_NextMap);
    CreateTimer(6.0, Timer_DoChangeMap, 0);
    return Plugin_Stop;
}

public Action Timer_DoChangeMap(Handle timer)
{
    if (IsMapValid(g_NextMap)) ServerCommand("changelevel %s", g_NextMap);
    else PrintToChatAll("\x04[MapCtrl]\x03 没有找到地图：\x04%s\x03，再见 ", g_NextMap);
    return Plugin_Stop;
}

public Action Timer_FinalAnnounce(Handle timer)
{
    PrintToChatAll("\x04[MapCtrl]\x03 最后祝您，身体健康，再见 ");
    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
}

public void Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
    if (g_IsCoop)
    {
        if (strlen(g_NextMap) > 0)
        {
            PrintToChatAll("\x04[MapCtrl]\x03 已完成本战役，11 秒后将自动换图...");
            CreateTimer(5.0, Timer_BeforeChangeMap, 0);
        }
        else 
        {
            PrintToChatAll("\x04[MapCtrl]\x03 已完成所有战役，自动换图已经结束 ");
            PrintToChatAll("\x04[MapCtrl]\x03 自动换图 v2.0.2 by Lyric");
            CreateTimer(5.0, Timer_FinalAnnounce, 0);
        }
    }
}
