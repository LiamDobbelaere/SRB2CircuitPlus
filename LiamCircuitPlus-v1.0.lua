local loadedSkins = {}
local bestTimes = {}
local bestTimesNames = {}

local function CircuitPlusNetVars(network) 
    loadedSkins = network(loadedSkins)
    bestTimes = network(bestTimes)
    bestTimesNames = network(bestTimesNames)
end

local function CircuitPlusInitializeIfNeeded(player)
    -- Makes sure these variables actually exist on the player
    if player.CircuitPlus_LastLaps == nil then
        player.CircuitPlus_LastLaps = 0
    end

    if player.CircuitPlus_Realtime == nil then
        player.CircuitPlus_Realtime = 0
    end
end

local function CircuitPlusMapLoad(mapnum)
    loadedSkins = {}
    bestTimes = {}
    bestTimesNames = {}

    -- Load in the skins
    for skin in skins.iterate do
        if skin.availability == 0 then
            for player in players.iterate do
                CONS_Printf(player, 'Skin '..skin.name..' will be used for Circuit!')
            end
            
            table.insert(loadedSkins, skin.name)
            bestTimes[skin.name] = -1
        end
    end

    for player in players.iterate do
        R_SetPlayerSkin(player, 0)
        player.CircuitPlus_LastLaps = player.laps
        player.CircuitPlus_Realtime = player.realtime

        CONS_Printf(player, 'There are '..#loadedSkins..' skins loaded')
    end
end

local function CircuitPlusPlayerThink(player)
    CircuitPlusInitializeIfNeeded(player)

    if (player.laps > player.CircuitPlus_LastLaps) then
        -- They just completed a lap
        player.CircuitPlus_LastLaps = player.laps
        
        local ticsTaken = player.realtime - player.CircuitPlus_Realtime
        local currentSkin = loadedSkins[1 + (player.laps - 1) % #loadedSkins]
        CONS_Printf(player, player.name..' completed a lap in '..ticsTaken..' tics')
        if bestTimes[currentSkin] == -1 or ticsTaken < bestTimes[currentSkin] then
            bestTimes[currentSkin] = ticsTaken
            bestTimesNames[currentSkin] = player.name
            CONS_Printf(player, player.name..' set a new record for '..currentSkin..'!')
        end

        local nextSkinIndex = 1 + player.laps % #loadedSkins

        CONS_Printf(player, player.name..' completed a lap! Setting skin to '..loadedSkins[nextSkinIndex])
        R_SetPlayerSkin(player, loadedSkins[nextSkinIndex])

        player.CircuitPlus_Realtime = player.realtime

    end
    player.CircuitPlus_LastLaps = player.laps
end

local function CircuitPlusHUDGame(v)
    local scrW = v.width() / v.dupx()
    local scrH = v.height() / v.dupy()

    if (#loadedSkins <= 0 or displayplayer.CircuitPlus_Realtime == nil) then
        return
    end

    local nextSkinIndex = 1 + (1 + displayplayer.laps) % #loadedSkins
    local ticsTaken = displayplayer.realtime - displayplayer.CircuitPlus_Realtime

    v.drawString(16, scrH - 64, "Next up: "..loadedSkins[nextSkinIndex])
    v.drawString(16, scrH - 32, ticsTaken)
     
end

local function CircuitPlusIntermission(v)
    hud.disable("intermissiontally")

    local yPos = 0
    for skinName, time in pairs(bestTimes) do
        v.drawString(16, 16 + yPos, skinName..': '..bestTimesNames[skinName]..' - '..time, V_PERIDOTMAP)

        yPos = yPos + 8
    end
end

addHook("NetVars", CircuitPlusNetVars)
addHook("MapLoad", CircuitPlusMapLoad)
addHook("PlayerThink", CircuitPlusPlayerThink)
hud.add(CircuitPlusHUDGame, "game")
hud.add(CircuitPlusIntermission, "intermission")